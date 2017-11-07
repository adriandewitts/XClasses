//
//  OpinionatedModel.swift
//  Sprite
//
//  Created by Adrian on 8/09/2016.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import Foundation
import Realm
import RealmSwift
import Firebase
import FirebaseStorage
import FileKit
import Alamofire
import IGListKit
import Hydra

protocol ViewModelDelegate {
    var _index: Int { get set }
    var properties: [String: String]  { get }
    var relatedCollection: [ViewModelDelegate] { get }
}

class RealmString: Object {
    @objc dynamic var stringValue = ""

    init(stringValue: String) {
        super.init()
        self.stringValue = stringValue
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    required init() {
        super.init()
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
}

enum SyncStatus: Int {
    case current
    case created
    case updated
    case deleted
    case upload
    case download
}

struct FileModel {
    let bucket: String
    let serverPath: String
    let localURL: String
    let expiry: Int
    let deleteOnUpload: Bool
}

public class ViewModel: Object, ViewModelDelegate, ListDiffable {
    static let tryAgain = 60.0

    var _index: Int = 0 // Position on current list in memory
    @objc dynamic var _sync = SyncStatus.created.rawValue // Record status for syncing
    @objc dynamic var id = 0 // Server ID - do not make primary key, as it is unchangeable
    @objc dynamic var clientId = UUID().uuidString // Used to make sure records arent saved to the server DB multiple times

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

    /// Can read from server
    class var read: Bool {
        return true
    }

    /// Can write to server
    class var write: Bool {
        return false
    }

    /// Needs authentication before reading or writing to server
    class var authenticate: Bool {
        return false
    }

    var properties: [String: String] {
        return [:]
    }

    var relatedCollection: [ViewModelDelegate] {
        return []
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
    */
    class var fileAttributes: [String: FileModel] {
        return ["default": FileModel(bucket: "default", serverPath: "/{clientID}.png", localURL: "/{clientID}.png", expiry: 3600, deleteOnUpload: true)]
    }

    // End of overrides

    class var count: Int {
        let realm = try! Realm()
        return realm.objects(self).count
    }

    class var empty: Bool {
        return self.count == 0
    }

    /// Return results of query
    class func find(query: NSPredicate? = nil, orderBy: String? = nil, orderAscending: Bool = false) -> Results<ViewModel> {
        let realm = try! Realm()
        var result = realm.objects(self)
        if query != nil {
            result = result.filter(query!)
        }
        if orderBy != nil {
            result = result.sorted(byKeyPath: orderBy!, ascending: orderAscending)
        }
        return result
    }

    /// Prepares the model as a Dictionary, excluding prefixed underscored properties
    func exportProperties() -> [String: String] {
        var properties = [String: String]()
        let schemaProperties = objectSchema.properties

        for property in schemaProperties {
            if !property.name.hasPrefix("_") {
                let value = self.value(forKey: property.name)
                let name = property.name.snakeCased()
                if property.type != .date {
                    properties[name] = String(describing: value!)
                }
                else {
                    let dateValue = value as! Date
                    properties[name] = dateValue.toUTCString()
                }
            }
        }

        if id == 0 {
            properties["id"] = ""
        }

        return properties
    }

    /// Imports the data from the CSV and does the type casting that it needs to do
    func importProperties(dictionary: [String: String], isNew: Bool)
    {
        let schemaProperties = objectSchema.properties
        let realm = try! Realm()
        
        try! realm.write {
            for property in schemaProperties
            {
                if !property.name.hasPrefix("_") && dictionary[property.name] != nil
                {
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
                    case .linkingObjects:
                        if property.objectClassName == "RealmString" {
                            let array = dictionary[property.name]!.components(separatedBy: ",")
                            let list = self[property.name] as! List<RealmString>
                            for element in array {
                                list.append(RealmString(stringValue: element))
                            }
                        }
                    default:
                        log(error: "Property type does not exist")
                    }
                }
            }

            _sync = SyncStatus.current.rawValue

            if isNew
            {
                realm.add(self)
            }
        }
    }

    // File handling

    func fileURL(forKey: String = "default") -> (URL, Bool)
    {
        let path = self.path(forKey: forKey)
        return (path.url, path.exists)
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

//    func getFile(key: String = "default", progress: @escaping (_ progress: Progress) -> Void = {_ in }, error: @escaping (_ error: Error) -> Void = {_ in }, completion: @escaping (_ url: URL) -> Void = {_ in})
//    {
//        let (localURL, exists) = fileURL(forKey: key)
//        if !exists
//        {
//            let fileAttributes = type(of: self).fileAttributes[key]!
//            let localURL = Path(replaceOccurrence(of: fileAttributes.localURL)).url
//            let serverPath = replaceOccurrence(of: fileAttributes.serverPath)
//
//            let storage = Storage.storage(url: "gs://" + fileAttributes.bucket)
//            let storageRef = storage.reference(forURL: "gs://" + fileAttributes.bucket + serverPath)
//
//            let downloadTask = storageRef.write(toFile: localURL)
//
//            downloadTask.observe(.progress) { snapshot in
//                progress(snapshot.progress!)
//            }
//
//            let selfRef = ThreadSafeReference(to: self)
//
//            downloadTask.observe(.success) { snapshot in
//                completion(localURL)
//                if self._sync == SyncStatus.download.rawValue
//                {
//                    let realm = try! Realm()
//                    let threadSafeSelf = realm.resolve(selfRef)!
//                    try! realm.write {
//                        threadSafeSelf._sync = SyncStatus.current.rawValue
//                    }
//                }
//            }
//
//            // Errors shouldn't happen - so log it and try again in a minute
//            downloadTask.observe(.failure) { snapshot in
//                log(error: snapshot.error!.localizedDescription)
//                Timer.scheduledTimer(withTimeInterval: ViewModel.tryAgain, repeats: false, block: { timer in
//                    self.getFile(key: key, progress: progress, completion: completion)
//                })
//                // TODO: will send back only errors that the user sees in a modal
//                error(snapshot.error!)
//            }
//        }
//        else
//        {
//            completion(localURL)
//        }
//    }

    // TODO: return wait flag
    func putFile(key: String = "default", progress: @escaping (_ progress: Progress) -> Void = {_ in }, error: @escaping (_ error: Error) -> Void = {_ in }, completion: @escaping (_ url: URL) -> Void = {_ in})
    {
        let fileAttributes = type(of: self).fileAttributes[key]!
        let localURL = Path(replaceOccurrence(of: fileAttributes.localURL)).url
        let serverPath = replaceOccurrence(of: fileAttributes.serverPath)

        let storage = Storage.storage(url: "gs://" + fileAttributes.bucket)
        let storageRef = storage.reference(forURL: "gs://" + fileAttributes.bucket + serverPath)
        let metadata = StorageMetadata()
        metadata.customMetadata = exportProperties()

        let uploadTask = storageRef.putFile(from: localURL, metadata: metadata)

        uploadTask.observe(.progress) { snapshot in
            progress(snapshot.progress!)
        }

        let selfRef = ThreadSafeReference(to: self)

        uploadTask.observe(.success) { snapshot in
            completion(localURL)
            let realm = try! Realm()
            let threadSafeSelf = realm.resolve(selfRef)!

            if threadSafeSelf._sync == SyncStatus.download.rawValue
            {
                if threadSafeSelf._sync == SyncStatus.upload.rawValue
                {
                    try! realm.write {
                        threadSafeSelf._sync = SyncStatus.current.rawValue
                    }
                }
                if fileAttributes.deleteOnUpload
                {
                    try! FileManager.default.removeItem(at: localURL)
                }
            }
        }

        // Errors shouldn't happen - so log it and try again in a minute
        uploadTask.observe(.failure) { snapshot in
            log(error: snapshot.error!.localizedDescription)
            Timer.scheduledTimer(withTimeInterval: ViewModel.tryAgain, repeats: false, block: { timer in
                self.putFile(key: key, progress: progress, completion: completion)
            })
            // TODO: will send back only errors that the user sees in a modal
            error(snapshot.error!)
        }
    }

//    func streamFile(key: String = "default", progress: @escaping (_ temporyURL: URL) -> Void = {_ in }, error: @escaping (_ error: Error) -> Void = {_ in }, completion: @escaping (_ url: URL) -> Void = {_ in}) {
//        let source = serverURL(forKey: key)
//        let (localURL, exists) = fileURL()
//
//        if !exists {
//            Alamofire.download(source, to: { temp, response in
//                // Move these back to the main thread, else Realm will get the shits down the line.
//                // Assumes this is originally called from the main thread
//                DispatchQueue.main.async {
//                    progress(temp)
//                }
//                return (localURL, [.removePreviousFile, .createIntermediateDirectories])
//            }).response { response in
//                DispatchQueue.main.async {
//                    if response.error != nil {
//                        completion(response.destinationURL!)
//                    }
//                    else {
//                        //TODO: Humanise the error for display in modal
//                        //error(response.error!)
//                    }
//                }
//            }
//        }
//        else {
//            completion(localURL)
//        }
//    }

    // TODO: Add Progress to method, and track with Alamofire
    func streamFile(key: String = "default", completion: @escaping (_ url: URL) -> Void = {_ in}) -> Promise<URL> {
        let source = self.serverURL(forKey: key)
        let (localURL, exists) = self.fileURL()
        return Promise<URL>({ resolve, reject, _ in
            if !exists {
                Alamofire.download(source, to: { temp, response in
                    print("*** get temp")
                    resolve(temp)
                    return (localURL, [.removePreviousFile, .createIntermediateDirectories])
                }).response { response in
                    if response.error == nil {
                        print("*** get complete file")
                        completion(response.destinationURL!)
                    }
                    else {
                        log(error: response.error.debugDescription)
                        reject(CommonError.networkConnectionError)
                    }
                }
            }
            else {
                resolve(localURL)
            }
        })
    }

    // TODO: Add Progress to method
    func getFile(key: String = "default") -> Promise<URL>
    {
        let selfRef = ThreadSafeReference(to: self)
        let (localURL, exists) = self.fileURL(forKey: key)
        return Promise<URL>(in: .background, { resolve, reject, _ in
            if !exists
            {
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
                    if self._sync == SyncStatus.download.rawValue
                    {
                        let realm = try! Realm()
                        let threadSafeSelf = realm.resolve(selfRef)!
                        try! realm.write {
                            threadSafeSelf._sync = SyncStatus.current.rawValue
                        }
                    }
                }

                downloadTask.observe(.failure) { snapshot in
                    log(error: snapshot.error!.localizedDescription)
                    reject(CommonError.miscellaneousNetworkError)
                }
            }
            else
            {
                resolve(localURL)
            }
        })
    }

//    resolve((data, response))
//    reject("Image cannot be decoded")

//    func syncFiles()
//    {
//        if _sync == SyncStatus.upload.rawValue
//        {
//            let keys = type(of: self).fileAttributes.keys
//            for key in keys
//            {
//                putFile(key: key)
//            }
//        }
//        else if _sync == SyncStatus.download.rawValue
//        {
//            let keys = type(of: self).fileAttributes.keys
//            for key in keys
//            {
//                getFile(key: key)
//            }
//        }
//    }

    private func replaceOccurrence(of: String) -> String
    {
        var replacement = of
        let schemaProperties = objectSchema.properties
        for property in schemaProperties
        {
            replacement = replacement.replacingOccurrences(of: "{\(property.name)}", with: String(describing: self[property.name]!))
        }

        return replacement.replacingOccurrences(of: "{uid}", with: SyncController.sharedInstance.uid)
    }
}



// TODO: Record cleanup - periodically - when a certain age
// TODO: File cleanup after certain age

// File jobs and status
// model, clientID, progress, lastProgressTime
// status: toTransfer, transferring, transferred, pause?
