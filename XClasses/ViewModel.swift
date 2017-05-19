//
//  OpinionatedModel.swift
//  Sprite
//
//  Created by Adrian on 8/09/2016.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import Foundation
import RealmSwift
import Firebase
import FirebaseStorage
import FileKit

protocol ViewModelDelegate
{
    var _index: Int { get set }
    static func table() -> String
    static func tableVersion() -> Float
    static func tableView() -> String
    static func readOnly() -> Bool
    func properties() -> [String: String]
    func relatedCollection() -> [ViewModelDelegate]
    func exportProperties() -> [String: String]
}

class RealmString: Object
{
    dynamic var stringValue = ""
}

enum SyncStatus: Int
{
    case current
    case created
    case updated
    case deleted
    case upload
    case download
}

struct FileModel
{
    let bucket: String
    let serverPath: String
    let localURL: String
    let expiry: Int
    let deleteOnUpload: Bool
}

public class ViewModel: Object, ViewModelDelegate
{
    var _index: Int = 0 // Position on current list in memory
    dynamic var _sync = SyncStatus.created.rawValue // Record status for syncing
    dynamic var id = 0 // Server ID - do not make primary key, as it gets locked
    dynamic var clientId = UUID().uuidString // Used to make sure records arent saved to the server DB multiple times

    // Mark: Override in subclass

    override public static func primaryKey() -> String?
    {
        return "clientId"
    }

    override public static func indexedProperties() -> [String]
    {
        return ["_sync", "id"]
    }

    class func table() -> String
    {
        return String(describing: self)
    }

    class func tableVersion() -> Float
    {
        return 1.0
    }

    class func tableView() -> String
    {
        return "default"
    }

    class func readOnly() -> Bool
    {
        return false
    }

    func properties() -> [String: String]
    {
        return ["title": "Placeholder", "path": "/", "image": "default.png"]
    }

    func relatedCollection() -> [ViewModelDelegate]
    {
        return [ViewModel()]
    }

    override public static func ignoredProperties() -> [String]
    {
        return ["_index"]
    }

    // serverURL: gs:// url on google cloud storage
    // localURL: path to url on device - is parsed to include id or clientid
    // expiry: when file is deleted locally (in seconds)
    // deleted on upload: as it says
    class func fileAttributes() -> [String: FileModel]
    {
        return ["default": FileModel(bucket: "gs://default/", serverPath: "{clientID}.png", localURL: "/{clientID}.png", expiry: 3600, deleteOnUpload: true)]
    }

    // End of overrides

    // Prepares the model as a Dictionary, excluding prefixed underscored properties
    func exportProperties() -> [String: String]
    {
        var properties = [String: String]()
        let schemaProperties = self.objectSchema.properties

        for property in schemaProperties
        {
            if !property.name.hasPrefix("_")
            {
                let value = self.value(forKey: property.name)
                let name = property.name.snakeCase()
                if property.type != .date
                {
                    properties[name] = String(describing: value!)
                }
                else
                {
                    let dateValue = value as! Date
                    properties[name] = dateValue.toUTCString()
                }
            }
        }

        if self.id == 0
        {
            properties["id"] = ""
        }

        return properties
    }

    // Imports the data from the CSV and does the type casting that it needs to do
    func importProperties(dictionary: [String: String], isNew: Bool)
    {
        let schemaProperties = self.objectSchema.properties
        let realm = try! Realm()
        
        try! realm.write {
            for property in schemaProperties
            {
                if !property.name.hasPrefix("_") && dictionary[property.name] != nil
                {
                    switch property.type {
                    case .string:
                        self[property.name] = dictionary[property.name]!
                    case .int:
                        self[property.name] = Int(dictionary[property.name]!)
                    case .float:
                        self[property.name] = Float(dictionary[property.name]!)
                    case .double:
                        self[property.name] = Double(dictionary[property.name]!)
                    case .bool:
                        self[property.name] = dictionary[property.name]!.lowercased() == "true"
                    case .date:
                        self[property.name] = Date.from(UTCString: dictionary[property.name]!)
                    default:
                        Analytics.logEvent("iOS Error", parameters: ["error": "Property type does not exist" as NSObject])
                    }
                }
            }

            self._sync = SyncStatus.current.rawValue

            if isNew
            {
                realm.add(self)
            }
        }
    }

    func fileURL(forKey: String = "default") -> (URL, Bool)
    {
        let path = self.path(forKey: forKey)
        return (path.url, path.exists)
    }

    func path(forKey: String = "default") -> Path
    {
        let fileAttributes = type(of: self).fileAttributes()[forKey]!
        return Path(self.replaceOccurrence(of: fileAttributes.localURL))
    }

    func getFile(controller: SyncControllerDelegate?, key: String = "default")
    {
        let fileAttributes = type(of: self).fileAttributes()[key]!
        let localURL = Path(self.replaceOccurrence(of: fileAttributes.localURL)).url
        let serverPath = self.replaceOccurrence(of: fileAttributes.serverPath)

        let storage = Storage.storage(url: fileAttributes.bucket)
        let storageRef = storage.reference(forURL: fileAttributes.bucket + serverPath)

        _ = storageRef.write(toFile: localURL)
        { url, error in
            if let error = error
            {
                print(error)
            }
            else
            {
                if self._sync == SyncStatus.download.rawValue
                {
                    let realm = try! Realm()
                    try! realm.write {
                        self._sync = SyncStatus.current.rawValue
                    }
                }
            }
        }
    }

    func putFile(controller: SyncControllerDelegate?, key: String = "default")
    {
        let fileAttributes = type(of: self).fileAttributes()[key]!
        let localURL = Path(self.replaceOccurrence(of: fileAttributes.localURL)).url
        let serverPath = self.replaceOccurrence(of: fileAttributes.serverPath)

        let storage = Storage.storage(url: fileAttributes.bucket)
        let storageRef = storage.reference(forURL: fileAttributes.bucket + serverPath)
        let metadata = StorageMetadata()
        metadata.customMetadata = self.exportProperties()

        _ = storageRef.putFile(from: localURL, metadata: metadata)
        { metadata, error in
            if let error = error
            {
                print(error)
            }
            else
            {
                if self._sync == SyncStatus.upload.rawValue
                {
                    let realm = try! Realm()
                    try! realm.write {
                        self._sync = SyncStatus.current.rawValue
                    }
                }
                if fileAttributes.deleteOnUpload
                {
                    try! FileManager.default.removeItem(at: localURL)
                }
                // Metadata contains file metadata such as size, content-type, and download URL.
                //let downloadURL = metadata!.downloadURL()
                // TODO: set file locations
                // TODO: monitor uploads and downloads progress and send to delegate
            }
        }
    }

    private func replaceOccurrence(of: String) -> String
    {
        var replacement = of
        let schemaProperties = self.objectSchema.properties
        for property in schemaProperties
        {
            replacement = replacement.replacingOccurrences(of: "{\(property.name)}", with: String(describing: self[property.name]!))
        }

        return replacement.replacingOccurrences(of: "{uid}", with: SyncController.sharedInstance.uid)
    }


    func syncFiles()
    {
        if self._sync == SyncStatus.upload.rawValue
        {
            let keys = type(of: self).fileAttributes().keys
            for key in keys
            {
                self.putFile(controller: nil, key: key)
            }
        }
        else if self._sync == SyncStatus.download.rawValue
        {
            let keys = type(of: self).fileAttributes().keys
            for key in keys
            {
                self.getFile(controller: nil, key: key)
            }
        }
    }
}

// TODO: Removal of record - periodically - when a certain age
// TODO: File cleanup after certain age

// File jobs
// model, clientID, progress, lastProgressTime
// status: toTransfer, transferring, transferred, pause?
