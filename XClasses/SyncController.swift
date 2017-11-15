//
//  SyncController.swift
//  Bookbot
//
//  Created by Adrian on 29/4/17.
//  Copyright © 2017 Adrian DeWitts. All rights reserved.
//

import Foundation
import Firebase
import RealmSwift
import Moya
import FileKit
import Hydra

/// Sync model stores meta data for each model
public class SyncModel: Object
{
    @objc dynamic var modelName = ""
    @objc dynamic var serverSync = Date.distantPast // Server timestamp of last server sync. To be used on next sync request
    @objc dynamic var readLock = Date.distantPast
    @objc dynamic var writeLock = Date.distantPast
}

public class SyncController
{
    static let sharedInstance = SyncController()
    static let serverTimeout = 60.0
    static let retries = 60
    static let retrySleep: UInt32 = 1
    var uid = ""

    /// Configure sets up the meta data for each synced table
    func configure(models: [AnyClass]) {
        let realm = try! Realm()

        for m in models {
            let model = "\(m)"
            if realm.objects(SyncModel.self).filter("modelName = '\(model)'").count == 0 {
                try! realm.write { realm.add(SyncModel(value: ["modelName": model])) }
            }
        }

        // TODO: Remove deleted objects from tables
    }

    /// Configure file will create needed folders to store synced files
    func configureFile(models: [AnyClass]) {
        for m in models {
            let model = m as! ViewModel.Type
            let paths = model.fileAttributes
            for p in paths {
                let path = Path(p.value.localURL).parent
                if !path.exists {
                    try! path.createDirectory()
                }
            }
        }
    }

    /// Token will get the user token and return this as a Promise
    func token() -> Promise<String> {
        return Promise<String> { resolve, reject, _ in
            guard let user = Auth.auth().currentUser else {
                log(error: "User has not authenticated")
                reject(CommonError.authenticationError)
                return
            }

            self.uid = user.uid
            user.getIDToken() { token, error in
                if let error = error {
                    log(error: error.localizedDescription)
                    reject(error)
                    return
                }
                resolve(token!)
            }
        }
    }

    /// Sync will read and write sync specific models. If there is no token it will attempt to read with guest permissions. Will not attempt a retry if there are any issues.
    func sync(models: [ViewModel.Type])
    {
        token().then(in: .utility) { token in
            for model in models {
                self.writeSync(model: model, token: token)
                self.readSync(model: model, token: token).then(in: .utility) {}
            }
        }.catch() { error in
            for model in models {
                self.readSync(model: model, token: nil).then(in: .utility) {}
                // Never has write sync because write needs to be authenticated
            }
        }
    }

    /// Instead of responding with a Promise of results, instead return the sync is ready. The reason for this is that it is more code to move the Realm response over the thread
    func syncReady(model: ViewModel.Type, freshness: Double = 600.0, timeout: Double = 10.0) -> Promise<Void> {
        return Promise<Void> { resolve, reject, _ in
            let realm = try! Realm()
            guard let syncModel = realm.objects(SyncModel.self).filter(NSPredicate(format: "modelName = '\(model)'")).first else {
                reject(CommonError.unexpectedError)
                return
            }

            let interval = syncModel.serverSync.timeIntervalSince(Date())
            if interval < freshness && !model.empty {
                resolve(Void())
            }

            self.retrySync(model: model).timeout(in: .userInitiated, timeout: timeout, error: CommonError.timeoutError).then() { _ in
                resolve(Void())
            }.catch() { error in
                reject(error)
            }
        }
    }

    /// Read sync will get token, and retry the sync
    func retrySync(model: ViewModel.Type) -> Promise<Void>
    {
        return Promise<Void> { resolve, reject, _ in
            self.token().then() { token in
                self.readSync(model: model, token: token, qos: .userInitiated).retry(SyncController.retries) {_,_ in sleep(SyncController.retrySleep); return true }.then { _ in
                    resolve(Void())
                }.catch { error in
                    reject(error)
                }
            }.catch() { _ in
                self.readSync(model: model, token: nil, qos: .userInitiated).retry(SyncController.retries) {_,_ in sleep(SyncController.retrySleep); return true }.then { _ in
                    resolve(Void())
                }.catch { error in
                    reject(error)
                }
            }
        }
    }

    /// Read sync make a request to the web service and stores new record to the local DB. Will also delete record marked for deletion
    func readSync(model: ViewModel.Type, token: String? = nil, qos: DispatchQoS.QoSClass = .utility) -> Promise<Void> {
        return Promise<Void> { resolve, reject, _ in
            let realm = try! Realm()

            let provider = MoyaProvider<WebService>(callbackQueue: DispatchQueue.global(qos: qos))//plugins: [NetworkLoggerPlugin(verbose: true)])

            let modelClass = model
            let model = "\(model)"

            // Make sure model is not sync locked
            let minuteAgo = Date.init(timeIntervalSinceNow: -SyncController.serverTimeout)
            var predicate = NSPredicate(format: "modelName = '\(model)' AND readLock < %@", minuteAgo as CVarArg)
            guard let syncModel = realm.objects(SyncModel.self).filter(predicate).first else {
                reject(CommonError.permissionError)
                return
            }

            // Make sure model has permission
            let authenticated = (modelClass.authenticate == true && token != nil) || modelClass.authenticate == false
            guard authenticated, modelClass.read == true else {
                reject(CommonError.permissionError)
                return
            }

            var timestamp = Date.distantPast
            try! realm.write { syncModel.readLock = Date() }
            let syncModelRef = ThreadSafeReference(to: syncModel)

            // Make request with Moya
            provider.request(.read(version: modelClass.tableVersion, table: modelClass.table, view: modelClass.tableView, accessToken: token, lastTimestamp: syncModel.serverSync, predicate: nil)) { result in
                // Local realm needed for thread
                let realm = try! Realm()
                switch result {
                case let .success(moyaResponse):
                    guard moyaResponse.statusCode == 200 else {
                        // TODO: if 403 show login modal
                        log(error: "Server returned status code \(moyaResponse.statusCode) while trying to read sync")
                        reject(CommonError.permissionError)
                        return
                    }
                    do
                    {
                        let response = try moyaResponse.mapString()
                        let l = response.components(separatedBy: "\n")
                        let meta = l[0].components(separatedBy: "|")
                        timestamp = Date.from(UTCString: meta[1])!
                        let h = l[1].components(separatedBy: "|")
                        let header = h.map { $0.camelCased() }
                        let lines = l.dropFirst(2)
                        let idIndex = header.index(of: "id")!
                        for line in lines
                        {
                            let components = line.components(separatedBy: "|")
                            let id = components[idIndex]
                            predicate = NSPredicate(format: "id = \(id)")

                            var dict = [String: String]()
                            for (index, property) in header.enumerated()
                            {
                                dict[property] = components[index]
                            }

                            let record = realm.objects(modelClass).filter(predicate).first
                            if (dict["delete"] == nil) || (dict["delete"] != "true") {
                                if record != nil {
                                    record!.importProperties(dictionary: dict, isNew:false)
                                }
                                else {
                                    let record = modelClass.init()
                                    record.importProperties(dictionary: dict, isNew: true)
                                }
                            }
                            else {
                                try! realm.write {
                                    if let record = record {
                                        record.deleted = true
                                    }
                                }
                            }
                        }
                    }
                    catch {
                        log(error: "Response was impossibly incorrect")
                        reject(CommonError.miscellaneousNetworkError)
                    }
                case let .failure(error):
                    log(error: "Server connectivity error\(error.localizedDescription)")
                    reject(CommonError.networkConnectionError)
                }

                let safeSyncModel = realm.resolve(syncModelRef)!
                try! realm.write {
                    safeSyncModel.readLock = Date.distantPast
                    safeSyncModel.serverSync = timestamp
                }
                resolve(Void())
            }
        }
    }

    //TODO: Clean up
    func writeSync(model: ViewModel.Type, token: String, qos: DispatchQoS.QoSClass = .utility)
    {
        let realm = try! Realm()
        let provider = MoyaProvider<WebService>(callbackQueue: DispatchQueue.global(qos: qos))

        let modelClass = model
        let model = "\(model)"

        // This section handles the writes to server DB
        // Checks if class can write, has a writelock (max 1 minute), and has something to write
        if modelClass.write == true
        {
            let minuteAgo = Date.init(timeIntervalSinceNow: -SyncController.serverTimeout)
            var predicate = NSPredicate(format: "modelName = '\(model)' AND writeLock < %@", minuteAgo as CVarArg)
            if let syncModel = realm.objects(SyncModel.self).filter(predicate).first
            {
                try! realm.write { syncModel.writeLock = Date() }
                predicate = NSPredicate(format: "_sync = \(SyncStatus.created.rawValue) OR _sync = \(SyncStatus.updated.rawValue)")
                let toSave = realm.objects(modelClass).filter(predicate)
                if toSave.count > 0
                {
                    provider.request(.createAndUpdate(version: modelClass.tableVersion, table: modelClass.table, view: modelClass.tableView, accessToken: token, records: Array(toSave)))
                    { result in
                        // Local realm needed for thread
                        let realm = try! Realm()
                        switch result {
                        case let .success(moyaResponse):
                            if moyaResponse.statusCode == 200
                            {
                                do
                                {
                                    let response = try moyaResponse.mapString()
                                    let lines = response.components(separatedBy: "\n").dropFirst()
                                    for line in lines
                                    {
                                        let components = line.components(separatedBy: "|")
                                        let id = Int(components[0])!
                                        let cid = components[1]
                                        predicate = NSPredicate(format: "id = \(id) OR clientId = '\(cid)'")
                                        let item = toSave.filter(predicate).first!
                                        try! realm.write {
                                            item.id = id
                                            item._sync = SyncStatus.current.rawValue
                                        }
                                    }
                                }
                                catch { log(error: "Response was impossibly incorrect") }
                            }
                            else
                            {
                                // TODO: if 403 show login modal
                                log(error: "Server returned status code \(moyaResponse.statusCode) while trying to write sync")
                                //Timer.scheduledTimer(withTimeInterval: SyncController.serverTimeout, repeats: false, block: { timer in self.sync(models: models)})
                            }
                        case let .failure(error):
                            // TODO: If timer exists don't schedule another timer
                            log(error: error.errorDescription!)
                            //Timer.scheduledTimer(withTimeInterval: SyncController.serverTimeout, repeats: false, block: { timer in self.sync(models: models)})
                        }
                        //try! realm.write { syncModel.writeLock = Date.distantPast }
                    }

                    // Delete records section
                    predicate = NSPredicate(format: "_sync = \(SyncStatus.deleted.rawValue)")
                    let toDelete = realm.objects(modelClass).filter(predicate)
                    if toDelete.count > 0
                    {
                        provider.request(.delete(version: modelClass.tableVersion, table: modelClass.table, view: modelClass.tableView, accessToken: token, records: Array(toDelete)))
                        { result in
                            switch result {
                            case let .success(moyaResponse):
                                if moyaResponse.statusCode == 200
                                {
                                    // As long as the status code is a success, we will delete these objects
                                    try! realm.write { realm.delete(toDelete) }
                                }
                                else
                                {
                                    log(error: "Either user was trying to delete records they can't or something went wrong with the server")
                                }
                            case let .failure(error):
                                log(error: error.errorDescription!)
                                //Timer.scheduledTimer(withTimeInterval: SyncController.serverTimeout, repeats: false, block: { timer in self.sync(models: models)})
                            }
                            //try! realm.write { syncModel.writeLock = Date.distantPast }
                            // TODO: Update and delete would both need to finish to release (At the moment keeping them commented out so it locks for a min
                        }
                    }
                }
            }
        }
    }

//    func fileSync(models: [AnyClass])
//    {
//        // TODO: Needs robust checking and status
//        // TODO: Limit downloads and uploads at the same time
//        let realm = try! Realm()
//        let predicate = NSPredicate(format: "_sync = \(SyncStatus.upload.rawValue) or _sync = \(SyncStatus.download.rawValue) ")
//
//        for model in models
//        {
//            let result = realm.objects(model as! Object.Type).filter(predicate)
//            for item in result
//            {
//                (item as! ViewModel).syncFiles()
//            }
//        }
//    }
}
