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
import Alamofire
import IGListKit
import Hydra

protocol ViewModelDelegate {
    var properties: [String: String]  { get }
    var relatedCollection: Any { get }
}

enum SyncStatus: Int {
    case current
    case created
    case updated
    case deleted
}

struct FileModel {
    let bucket: String
    let serverPath: String
    let localURL: String
    let expiry: Int
    let deleteOnUpload: Bool
    let fileUpdatedField: String?
}

// TODO: Record cleanup - periodically - on fresh start
// TODO: File cleanup after certain age

public class ViewModel: Object, ViewModelDelegate, ListDiffable {
    static let tryAgain = 60.0

    @objc dynamic var _sync = SyncStatus.created.rawValue // Record status for syncing
    @objc dynamic var id = 0 // Server ID - do not make primary key, as they are unchangeable
    @objc dynamic var clientId = UUID().uuidString // Used to make sure records aren't saved to the server DB multiple times
    @objc dynamic var _deleted = false

    // Mark: Override in subclass

    override public class func primaryKey() -> String? {
        return "clientId"
    }

    override public class func indexedProperties() -> [String] {
        return ["_sync", "id"]
    }

    override public class func ignoredProperties() -> [String] {
        return ["_index"]
    }

    class var table: String {
        return String(describing: self)
    }

    class var tableVersion: Float {
        return 1.0
    }

    class var tableView: String {
        return "default"
    }

    class var internalVersion: Float {
        return 1.0
    }

    // Can read from service
    class var read: Bool {
        return true
    }

    // Can write to service
    class var write: Bool {
        return false
    }

    // Needs authentication before reading from server
    class var authenticate: Bool {
        return false
    }

    var properties: [String: String] {
        return [:]
    }

    var relatedCollection: Any {
        let realm = try! Realm()
        return realm.objects(ViewModel.self)
    }

    // ListDiffable implementation
    public func diffIdentifier() -> NSObjectProtocol {
        return clientId as NSObjectProtocol
    }

    public func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        if let object = object as? ViewModel {
            return clientId == object.clientId
        }
        return false
    }

    /**
    Override fileAttributes class method to map each remote to local file. Returns a dictionary with each mapped file.
    - **bucket** The google bucket storage name
    - **serverPath** The rest of the path of the folder within the bucket. Start with /
    - **localURL** Path to local file
    - **expiry** when file is deleted locally (in seconds)
    - **deleteOnUpload** as it says
    - **uploadStatusField**
    */
    class var fileAttributes: [String: FileModel] {
        return ["default": FileModel(bucket: "default", serverPath: "/{clientID}.png", localURL: "/{clientID}.png", expiry: 3600, deleteOnUpload: true, fileUpdatedField: "")]
    }

    // End of overrides

    /// Count all objects in the table
    class var count: Int {
        return objects().count
    }

    /// Check if the table is empty
    class var empty: Bool {
        return self.count == 0
    }

    class func findOrCreate(values: [String: Any], name: String) -> Self {
        if let result = Database.realm?.objects(self).filter("%@ = %@", name, values[name] as! CVarArg).first {
            return result
        }
        let newObject = self.init(value: values)
        Database.add(newObject)
        return newObject
    }

    class func objects() -> Results<ViewModel> {
        return Database.realm!.objects(self).filter("_deleted = false")
    }

//    class func object(forKey: String, value: String) -> Self? {
//        let table = Database.realm?.objects(self)
//        let filter = table?.filter("_deleted = false && \(forKey) = %@", value as! CVarArg)
//        return filter?.first
//    }

    func setAsUserDefault(forKey key: String) {
        if id > 0 {
            UserDefaults.standard.set(id, forKey: key + "Id")
        }

        UserDefaults.standard.set(clientId, forKey: key + "ClientId")
    }

    class func userDefault(key: String) -> Self? {
        let id = UserDefaults.standard.integer(forKey: key + "Id")
        if id > 0, let result = Database.objects(self).filter(NSPredicate(format: "id = %@", id)).first {
            return result
        }

        let clientId = UserDefaults.standard.string(forKey: key + "ClientId")
        return Database.objects(self).filter(NSPredicate(format: "clientId = %@", clientId ?? "")).first
    }

    /// Prepares the model as a Dictionary, excluding prefixed underscored properties
    func exportProperties() -> [String: String] {
        var properties = [String: String]()
        let schemaProperties = objectSchema.properties

        for property in schemaProperties {
            if !property.name.hasPrefix("_") {
                let value = self.value(forKey: property.name)
                let name = property.name.snakeCased()

                switch property.type {
                case .bool:
                    let boolValue = value as! Bool
                    properties[name] = boolValue ? "true" : "false"
                case .date:
                    let dateValue = value as! Date
                    properties[name] = dateValue.toUTCString()
                default:
                    properties[name] = String(describing: value!)
                }
            }
        }

        if id == 0 {
            properties["id"] = ""
        }

        return properties
    }

    /// Imports the data from a dictionary and does the type casting that it needs to do.
    func importProperties(dictionary: [String: String], isNew: Bool){
        let schemaProperties = objectSchema.properties
        for property in schemaProperties {
            if !property.name.hasPrefix("_") && dictionary[property.name] != nil {
                switch property.type {
                case .string:
                    let value = dictionary[property.name]!
                    if value != "" {
                        self[property.name] = value
                    }
                case .int:
                    if let number = Int(dictionary[property.name]!) {
                        self[property.name] = number
                    }
                case .float:
                    if let number = Float(dictionary[property.name]!) {
                        self[property.name] = number
                    }
                case .double:
                    if let number = Double(dictionary[property.name]!) {
                        self[property.name] = number
                    }
                case .bool:
                    let boolean = dictionary[property.name]!
                    if boolean != "" {
                        self[property.name] = boolean.lowercased() == "true"
                    }
                case .date:
                    if let date = Date.from(UTCString: dictionary[property.name]!) {
                        self[property.name] = date
                    }
                case .object:
                    if property.objectClassName == "RealmString" {
                        let array = dictionary[property.name]!.components(separatedBy: ",")
                        let list = self[property.name] as! List<RealmString>
                        for element in array {
                            list.append(RealmString.findOrCreate(element))
                        }
                    }
                default:
                    log(error: "\(property.name): \(property.type) \(String(describing: property.objectClassName)) property type does not exist")
                }
            }

            _sync = SyncStatus.current.rawValue
        }
    }

    // File handling

    func fileExists(forKey: String = "default") -> Bool {
        return path().exists
    }

    func fileURL(forKey: String = "default") -> (URL)
    {
        return path(forKey: forKey).url
    }

    func path(forKey: String = "default") -> Path
    {
        let fileAttributes = type(of: self).fileAttributes[forKey]!
        return Path(replaceOccurrence(of: fileAttributes.localURL))
    }

    func serverURL(forKey: String = "default") -> URL
    {
        let fileAttributes = type(of: self).fileAttributes[forKey]!
        return URL(string: "https://storage.googleapis.com/" + fileAttributes.bucket + replaceOccurrence(of: fileAttributes.serverPath))!
    }

    // TODO: Return promise, Add NSProgress
//    func putFile(key: String = "default", progress: @escaping (_ progress: Progress) -> Void = {_ in }, error: @escaping (_ error: Error) -> Void = {_ in }, completion: @escaping (_ url: URL) -> Void = {_ in})
//    {
//        let fileAttributes = type(of: self).fileAttributes[key]!
//        let localURL = Path(replaceOccurrence(of: fileAttributes.localURL)).url
//        let serverPath = replaceOccurrence(of: fileAttributes.serverPath)
//
//        let storage = Storage.storage(url: "gs://" + fileAttributes.bucket)
//        let storageRef = storage.reference(forURL: "gs://" + fileAttributes.bucket + serverPath)
//        let metadata = StorageMetadata()
//        metadata.customMetadata = exportProperties()
//
//        let uploadTask = storageRef.putFile(from: localURL, metadata: metadata)
//
//        uploadTask.observe(.progress) { snapshot in
//            progress(snapshot.progress!)
//        }
//
//        uploadTask.observe(.success) { snapshot in
//            completion(localURL)
//
//            if fileAttributes.deleteOnUpload
//            {
//                try! FileManager.default.removeItem(at: localURL)
//            }
//        }
//
//        // Errors shouldn't happen - so log it and try again in a minute
//        uploadTask.observe(.failure) { snapshot in
//            log(error: snapshot.error!.localizedDescription)
//            Timer.scheduledTimer(withTimeInterval: ViewModel.tryAgain, repeats: false, block: { timer in
//                self.putFile(key: key, progress: progress, completion: completion)
//            })
//            // TODO: will send back only errors that the user sees in a modal
//            error(snapshot.error!)
//        }
//    }

    // TODO: Add progress
    func putFile(key: String = "default") -> Promise<URL> {
        let selfRef = ThreadSafeReference(to: self)
        return Promise<URL>(in: .background, { resolve, reject, _ in
            guard let threadSafeSelf = Database.realm?.resolve(selfRef) else {
                return
            }

            let fileAttributes = type(of: threadSafeSelf).fileAttributes[key]!
            let localURL = Path(threadSafeSelf.replaceOccurrence(of: fileAttributes.localURL)).url
            let serverPath = threadSafeSelf.replaceOccurrence(of: fileAttributes.serverPath)

            let storage = Storage.storage(url: "gs://" + fileAttributes.bucket)
            let storageRef = storage.reference(forURL: "gs://" + fileAttributes.bucket + serverPath)
            let metadata = StorageMetadata()
            metadata.customMetadata = threadSafeSelf.exportProperties()

            let uploadTask = storageRef.putFile(from: localURL, metadata: metadata)

            //        uploadTask.observe(.progress) { snapshot in
            //        }

            uploadTask.observe(.success) { snapshot in
                resolve(localURL)

                if fileAttributes.deleteOnUpload {
                    try? FileManager.default.removeItem(at: localURL)
                }
            }

            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error {
                    log(error: error.localizedDescription)
                    reject(error)
                }
            }
        })
    }

    // Stream file. Return temp url with promise
    // Resume/restart stream if failure
    // -- Record last data event. If longer than 10 seconds, then restart download stream
    // move file to final location
    // on finish resolve promise
    // Add NSProgress
//    func streamFile(key: String = "default") -> Promise<URL> {
//        // This first part is outside the promise so Realm doesn't do its exception
//        let source = serverURL(forKey: key)
//        let (localURL, exists) = fileURL(forKey: key)
//
//        return Promise<URL>({ resolve, reject, _ in
//            if exists {
//                resolve(localURL)
//            }
//            else {
//                Alamofire.request(source.absoluteString).stream { data in
//                    resolve(localURL)
//                    try! data.append(fileURL: localURL)
//                }
//            }
//        })
//    }


    // TODO: Add NSProgress to method
    func getFile(key: String = "default", redownload: Bool = false) -> Promise<URL> {
        let selfRef = ThreadSafeReference(to: self)
        let localURL = fileURL(forKey: key)
        let exists = fileExists(forKey: key)
        return Promise<URL>(in: .background, { resolve, reject, _ in
            if !exists || redownload {
                let realm = try! Realm()
                let threadSafeSelf = realm.resolve(selfRef)!
                let fileAttributes = type(of: self).fileAttributes[key]!
                let localURL = Path(threadSafeSelf.replaceOccurrence(of: fileAttributes.localURL)).url
                let serverPath = threadSafeSelf.replaceOccurrence(of: fileAttributes.serverPath)

                let storage = Storage.storage(url: "gs://" + fileAttributes.bucket)
                let storageRef = storage.reference(forURL: "gs://" + fileAttributes.bucket + serverPath)

                let downloadTask = storageRef.write(toFile: localURL)

//                downloadTask.observe(.progress) { snapshot in
//                    progress(snapshot.progress!)
//                }

                downloadTask.observe(.success) { snapshot in
                    resolve(localURL)
                }

                downloadTask.observe(.failure) { snapshot in
                    log(error: snapshot.error!.localizedDescription)
                    reject(CommonError.miscellaneousNetworkError)
                }
            }
            else {
                resolve(localURL)
            }
        })
    }

    private func replaceOccurrence(of: String) -> String {
        var replacement = of
        let schemaProperties = objectSchema.properties
        for property in schemaProperties {
            replacement = replacement.replacingOccurrences(of: "{\(property.name)}", with: String(describing: self[property.name]!))
        }

        return replacement.replacingOccurrences(of: "{uid}", with: SyncController.shared.uid)
    }
}
