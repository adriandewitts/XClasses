//
//  OpinionatedModel.swift
//  Sprite
//
//  Created by Adrian on 8/09/2016.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import Firebase
import FirebaseStorage
import FileKit
import Alamofire
import IGListKit
import Hydra

/// Models need to conform to ViewModelDelegate for many of the sub classed view controlers in this framework.
protocol ViewModelDelegate {
    func viewProperty(forKey: String) -> Any?
    var relatedCollection: Array<ViewModelDelegate> { get }
}

/**
 SyncStatus contains the current syncronisation status of the ViewModel. This makes it easy to find records that need to be processed in syncronisation.
 - **current** The ViewModel is up to date.
 - **created** The ViewModel is new, and will need to be uploaded to the server.
 - **updated** The ViewModel has been updated since it's last sync, and will need to be uploaded to the server.
 - **deleted** The ViewModel is set to be deleted. This is so it can be deleted on the server, and then deleted in the client database.
 */
enum SyncStatus: Int {
    case current
    case created
    case updated
    case deleted
}

/**
 Filemodel contains information on the remote file.
 - **bucket** The google bucket storage name
 - **serverPath** The rest of the path of the folder within the bucket. Start with /
 - **localURL** Path to local file
 - **expiry** when file is deleted locally (in seconds)
 - **deleteOnUpload** as it says
 - **fileUpdatedField**
 */
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

/// When a model class sub classes the ViewModel it inherits the syncronisation functions that work with SyncControler. These include functions to serialise data, syncronisation functions and file uploading and downloading.
public class ViewModel: Object, ViewModelDelegate, ListDiffable {
    /// The default sync timeout across ViewModels
    static let tryAgain = 60.0
    
    /// Keeps the syncronisation status of a SyncStatus enum.
    @objc dynamic var _sync = SyncStatus.created.rawValue
    /// The server id. Do not make primary key as it is set on the first time it is synced.
    @objc dynamic var id = 0
    /// This is syncronised and useful for making sure records are not duplicated server side.
    @objc dynamic var clientId = UUID().uuidString // Used to make sure records aren't saved to the server DB multiple times
    /// Useful to ignore in searches.
    @objc dynamic var _deleted = false
    
    required init(value: [String: Any]) {
        super.init(value: value)
    }
    
    required init() {
        super.init()
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    // MARK: The default Realm overrides.
    
    override public class func primaryKey() -> String? {
        return "clientId"
    }

    override public class func indexedProperties() -> [String] {
        return ["_sync", "id"]
    }

    override public class func ignoredProperties() -> [String] {
        return ["_index"]
    }

    var ignoredWriteProperties: [String] {
        return []
    }
    
    // MARK: Other defaults to be overriden.

    /// The corresponding server database table.
    class var table: String {
        return String(describing: self)
    }

    /// The version of the table view.
    class var tableVersion: Float {
        return 1.0
    }

    /// This is akin to table views, and can have a subset of columns.
    class var tableView: String {
        return "default"
    }

    /// Can't rememeber why I needed to have internal versioning.
    class var internalVersion: Float {
        return 1.0
    }

    /// Can read from server.
    class var read: Bool {
        return true
    }

    /// Can write to server.
    class var write: Bool {
        return false
    }

    /// Needs authentication before reading from server.
    class var authenticate: Bool {
        return false
    }

    /// An array of related objects that relate to this object. In future will be a function that can have different types of related collections.
    var relatedCollection: Array<ViewModelDelegate> {
        return Array(Database.objects(ViewModel.self))
    }
    
    /// By default will return any of the objects properties for the View classes. This needs to be overriden to include calculated properties. In future would like to be able to return normal and calculated properties - but will require the moving away from Realm.
    func viewProperty(forKey: String) -> Any? {
        return self[forKey]
    }

    /// ListDiffable implementation for IGListKit.
    public func diffIdentifier() -> NSObjectProtocol {
        return clientId as NSObjectProtocol
    }

    /// ListDiffable implementation for IGListKit.
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
    - **fileUpdatedField**
    */
    class var fileAttributes: [String: FileModel] {
        return ["default": FileModel(bucket: "default", serverPath: "/{clientID}.png", localURL: "/{clientID}.png", expiry: 3600, deleteOnUpload: true, fileUpdatedField: "")]
    }

    // MARK: End of overrides

    /// Count all objects in the table.
    class var count: Int {
        return objects().count
    }

    /// Check if the table is empty.
    class var empty: Bool {
        return self.count == 0
    }

    /// Convenience function to either find the same existing record (by the name property), or create it new.
    class func findOrCreate(values: [String: Any], name: String, writeTransaction: Bool = true) -> Self {
        if let result = Database.realm?.objects(self).filter("%@ = %@", name, values[name] as! CVarArg).first {
            return result
        }
        let newObject = self.init(value: values)
        if writeTransaction {
            Database.add(newObject)
        }
        else {
            Database.realm?.add(newObject)
        }

        return newObject
    }

    /// Return all objects from the class and filter out _deleted.
    class func objects() -> Results<ViewModel> {
        return Database.realm!.objects(self).filter("_deleted = false")
    }

//    class func object(forKey: String, value: String) -> Self? {
//        let table = Database.realm?.objects(self)
//        let filter = table?.filter("_deleted = false && \(forKey) = %@", value as! CVarArg)
//        return filter?.first
//    }

    /// Convenience function for storing one of the records in the user defaults.
    func setAsUserDefault(forKey key: String) {
        if id > 0 {
            UserDefaults.standard.set(id, forKey: key + "Id")
        }

        UserDefaults.standard.set(clientId, forKey: key + "ClientId")
    }

    /// Convenience function for retrieving one of the records in the user defaults.
    class func userDefault(key: String) -> Self? {
        if let clientId = UserDefaults.standard.string(forKey: key + "ClientId") {
            return Database.objects(self).filter(NSPredicate(format: "clientId = %@", clientId )).first
        }
        
        let id = UserDefaults.standard.integer(forKey: key + "Id")
        if id > 0, let result = Database.objects(self).filter(NSPredicate(format: "id = %@", id)).first {
            return result
        }
        
        return nil
    }

    /// Prepares the model as a Dictionary, excluding prefixed underscored properties. This is used in syncronisation.
    func exportProperties() -> [String: String] {
        var properties = [String: String]()
        let schemaProperties = objectSchema.properties

        for property in schemaProperties {
            if !property.name.hasPrefix("_") && !ignoredWriteProperties.contains(property.name) {
                let value = self[property.name] // self.value(forKey: property.name)
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

    /// Imports the data from a dictionary and does the type casting that it needs to do. Used in syncronisation.
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
                        if isNew {
                            Database.update {
                                list.removeAll()
                            }
                        }
                        else {
                            list.removeAll()
                        }
                        
                        for element in array {
                            list.append(RealmString.findOrCreate(element, writeTransaction: isNew))
                        }
                    }
                default:
                    log(error: "\(property.name): \(property.type) \(String(describing: property.objectClassName)) property type does not exist")
                }
            }

            _sync = SyncStatus.current.rawValue
        }
    }

    // MARK: File handling

    /// Does file exist on file system.
    func fileExists(forKey: String = "default") -> Bool {
        return path().exists
    }

    /// Where is the file on the local file system.
    func fileURL(forKey: String = "default") -> (URL)
    {
        return path(forKey: forKey).url
    }

    /// Where is the path on the local file system.
    func path(forKey: String = "default") -> Path
    {
        let fileAttributes = type(of: self).fileAttributes[forKey]!
        return Path(replaceOccurrence(of: fileAttributes.localURL))
    }

    /// Whereis the server url of the syncronised file.
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
    /// Upload file to Google Cloud storage.
    func putFile(key: String = "default") -> Promise<URL> {
        let selfRef = ThreadSafeReference(to: self)
        return Promise<URL>(in: .main, { resolve, reject, _ in
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
    /// Get file from Google Cloud Storage.
    func getFile(key: String = "default", redownload: Bool = false) -> Promise<URL> {
        let selfRef = ThreadSafeReference(to: self)
        let localURL = fileURL(forKey: key)
        let exists = fileExists(forKey: key)
        return Promise<URL>(in: .main, { resolve, reject, _ in
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
