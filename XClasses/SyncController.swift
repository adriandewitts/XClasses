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
    @objc dynamic var deleteLock = Date.distantPast
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
        // Looking for a Realm Configuration in a separate Migrator class which is defined outside of the library
        var config = Migrator.configuration
        config.fileURL = (Path.userApplicationSupport + "default.realm").url
        Realm.Configuration.defaultConfiguration = config

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
        //TODO: Retry a few time if there is an error
        token().then(in: .utility) { token in
            for model in models {
                self.writeSync(model: model, token: token).then(in: .utility) {}
                self.deleteSync(model: model, token: token).then(in: .utility) {}
                self.readSync(model: model, token: token).then(in: .utility) {}
            }
        }.catch() { error in
            for model in models {
                self.readSync(model: model, token: nil).then(in: .utility) {}
                // Never has write sync because write needs to be authenticated
            }
        }
    }

    /// Instead of responding with a Promise of results, instead return the sync is ready. The reason for this is that it is more code to move the Realm response over the thread. Will also force the request and ignore the sync lock.
    func syncReady(model: ViewModel.Type, freshness: Double = 600.0, timeout: Double = 60.0) -> Promise<Void> {
        return Promise<Void> { resolve, reject, _ in
            // Get Sync Model (must be configured and ready)
            let realm = try! Realm()
            guard let syncModel = realm.objects(SyncModel.self).filter(NSPredicate(format: "modelName = '\(model)'")).first else {
                reject(CommonError.unexpectedError)
                return
            }

            // Is the sync fresh and there is record, then resolve
            let interval = syncModel.serverSync.timeIntervalSince(Date())
            if interval < freshness && !model.empty {
                resolve(Void())
            }

            // If not retry
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
                self.readSync(model: model, token: token, forceRequest: true, qos: .userInitiated).retry(SyncController.retries) {_,_ in sleep(SyncController.retrySleep); return true }.then { _ in
                    resolve(Void())
                }.catch { error in
                    reject(error)
                }
            }.catch() { _ in
                self.readSync(model: model, token: nil, forceRequest: true, qos: .userInitiated).retry(SyncController.retries) {_,_ in sleep(SyncController.retrySleep); return true }.then { _ in
                    resolve(Void())
                }.catch { error in
                    reject(error)
                }
            }
        }
    }

    /// Read sync make a request to the web service and stores new record to the local DB. Will also mark records for deletion
    func readSync(model: ViewModel.Type, token: String? = nil, forceRequest: Bool = false, qos: DispatchQoS.QoSClass = .utility) -> Promise<Void> {
        return Promise<Void> { resolve, reject, _ in
            let realm = try! Realm()

            let provider = MoyaProvider<WebService>(callbackQueue: DispatchQueue.global(qos: qos))//, plugins: [NetworkLoggerPlugin(verbose: true)])

            let modelClass = model
            let model = "\(model)"

            // Get model
            let minuteAgo = Date.init(timeIntervalSinceNow: -SyncController.serverTimeout)
            var predicate = forceRequest ? NSPredicate(format: "modelName = '\(model)'") : NSPredicate(format: "modelName = '\(model)' AND readLock < %@", minuteAgo as CVarArg)
            guard let syncModel = realm.objects(SyncModel.self).filter(predicate).first else {
                // Error could be because sync is misconfigured
                reject(CommonError.syncLockError)
                return
            }

            // Make sure model has permission
            let authenticated = (modelClass.authenticate == true && token != nil) || modelClass.authenticate == false
            guard authenticated, modelClass.read == true else {
                reject(CommonError.permissionError)
                return
            }

            // Make sync locked
            var timestamp = Date.distantPast
            try! realm.write { syncModel.readLock = Date() }
            let syncModelRef = ThreadSafeReference(to: syncModel)

            // Make request with Moya
            provider.request(.read(version: modelClass.tableVersion, table: modelClass.table, view: modelClass.tableView, accessToken: token, lastTimestamp: syncModel.serverSync, predicate: nil)) { result in
                // Local realm needed for thread
                let realm = try! Realm()

                defer {
                    let syncModel = realm.resolve(syncModelRef)!
                    try! realm.write {
                        syncModel.readLock = Date.distantPast
                        syncModel.serverSync = timestamp
                    }
                }

                switch result {
                case let .success(moyaResponse):
                    guard moyaResponse.statusCode == 200 else {
                        log(error: "Server returned status code \(moyaResponse.statusCode) while trying to read sync for \(model)")
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
                        var newRecords: [Object] = []
                        newRecords.reserveCapacity(lines.count)

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
                                if let record = record {
                                    try! realm.write {
                                        record.importProperties(dictionary: dict, isNew:false)
                                    }
                                }
                                else {
                                    let record = modelClass.init()
                                    record.importProperties(dictionary: dict, isNew: true)
                                    newRecords.append(record)
                                }
                            }
                            else {
                                try! realm.write {
                                    if let record = record {
                                        record._deleted = true
                                    }
                                }
                            }
                        }
                        try! realm.write {
                            realm.add(newRecords)
                        }
                    }
                    catch {
                        log(error: "Response was impossibly incorrect")
                        reject(CommonError.miscellaneousNetworkError)
                    }
                case let .failure(error):
                    log(error: "Server connectivity error \(error.localizedDescription)")
                    reject(CommonError.networkConnectionError)
                }

                resolve(Void())
            }
        }
    }

    func writeSync(model: ViewModel.Type, token: String? = nil, qos: DispatchQoS.QoSClass = .utility) -> Promise<Void> {
        return Promise<Void> { resolve, reject, _ in
            let realm = try! Realm()
            let provider = MoyaProvider<WebService>(callbackQueue: DispatchQueue.global(qos: qos))//, plugins: [NetworkLoggerPlugin(verbose: true)])

            let modelClass = model
            let model = "\(model)"

            // Make sure there are records to save
            var predicate = NSPredicate(format: "_sync = \(SyncStatus.created.rawValue) OR _sync = \(SyncStatus.updated.rawValue)")
            let syncRecords = realm.objects(modelClass).filter(predicate)
            guard syncRecords.count > 0 else {
                return
            }

            // Make sure model is not sync locked
            let minuteAgo = Date.init(timeIntervalSinceNow: -SyncController.serverTimeout)
            predicate = NSPredicate(format: "modelName = '\(model)' AND writeLock < %@", minuteAgo as CVarArg)
            guard let syncModel = realm.objects(SyncModel.self).filter(predicate).first else {
                reject(CommonError.syncLockError)
                return
            }

            // Make sure model has permission. Writes/POST always must have authentication
            guard token != nil, modelClass.write == true else {
                reject(CommonError.permissionError)
                return
            }

            //var timestamp = Date.distantPast
            try! realm.write {
                syncModel.writeLock = Date()
            }

            let syncModelRef = ThreadSafeReference(to: syncModel)            
            var syncSlice: [ViewModel] = []
            
            // 1000 seems to get close to the 60 second limit for updates, so 500 gives it some room to breath
            let limit = 500
            syncSlice.reserveCapacity(limit)
            var count = 0
            for record in syncRecords {
                count += 1
                if count >= limit {
                    break
                }
                syncSlice.append(record)
            }

            provider.request(.createAndUpdate(version: modelClass.tableVersion, table: modelClass.table, view: modelClass.tableView, accessToken: token!, records: syncSlice)) { result in
                // Local realm needed for thread
                let realm = try! Realm()

                defer {
                    let syncModel = realm.resolve(syncModelRef)!
                    try! realm.write {
                        syncModel.writeLock = Date.distantPast
                    }
                }

                switch result {
                case let .success(moyaResponse):
                    if moyaResponse.statusCode == 200 {
                        do {
                            let response = try moyaResponse.mapString()
                            let lines = response.components(separatedBy: "\n").dropFirst()
                            for line in lines {
                                let components = line.components(separatedBy: "|")
                                let id = Int(components[0])!
                                let cid = components[1]
                                predicate = NSPredicate(format: "id = \(id) OR clientId = '\(cid)'")
                                let item = realm.objects(modelClass).filter(predicate).first!
                                try! realm.write {
                                    item.id = id
                                    item._sync = SyncStatus.current.rawValue
                                }
                            }
                        }
                        catch {
                            log(error: "Response was impossibly incorrect")
                            reject(CommonError.unexpectedError)
                        }
                    }
                    else {
                        log(error: "Server returned status code \(moyaResponse.statusCode) while trying to write sync for \(model).")
                        print(try! moyaResponse.mapString())
                        reject(CommonError.permissionError)
                    }
                case let .failure(error):
                    log(error: error.errorDescription!)
                    reject(CommonError.networkConnectionError)
                }
            }
        }
    }

    func deleteSync(model: ViewModel.Type, token: String? = nil, qos: DispatchQoS.QoSClass = .utility) -> Promise<Void> {
        return Promise<Void> { resolve, reject, _ in
            let realm = try! Realm()
            let provider = MoyaProvider<WebService>(callbackQueue: DispatchQueue.global(qos: qos))//, plugins: [NetworkLoggerPlugin(verbose: true)])

            let modelClass = model
            let model = "\(model)"

            // Make sure there are records to delete
            var predicate = NSPredicate(format: "_sync = \(SyncStatus.deleted.rawValue)")
            let syncRecords = realm.objects(modelClass).filter(predicate)
            guard syncRecords.count > 0 else {
                return
            }

            // Make sure model is not sync locked
            let minuteAgo = Date.init(timeIntervalSinceNow: -SyncController.serverTimeout)
            predicate = NSPredicate(format: "modelName = '\(model)' AND deleteLock < %@", minuteAgo as CVarArg)
            guard let syncModel = realm.objects(SyncModel.self).filter(predicate).first else {
                reject(CommonError.syncLockError)
                return
            }

            // Make sure model has permission. Delete always must have authentication
            guard token != nil, modelClass.write == true else {
                reject(CommonError.permissionError)
                return
            }

            //var timestamp = Date.distantPast
            try! realm.write {
                syncModel.deleteLock = Date()
            }
            let syncModelRef = ThreadSafeReference(to: syncModel)
            let syncRecordsRef = ThreadSafeReference(to: syncRecords)

            provider.request(.delete(version: modelClass.tableVersion, table: modelClass.table, view: modelClass.tableView, accessToken: token!, records: Array(syncRecords))) { result in
                switch result {
                case let .success(moyaResponse):
                    let realm = try! Realm()
                    if moyaResponse.statusCode == 200 {
                        // As long as the status code is a success, we will delete these objects
                        let syncRecords = realm.resolve(syncRecordsRef)!
                        try! realm.write {
                            realm.delete(syncRecords)
                        }
                    }
                    else {
                        log(error: "Either user was trying to delete records they can't or something went wrong with the server")
                        reject(CommonError.permissionError)
                    }
                case let .failure(error):
                    log(error: error.errorDescription!)
                    reject(CommonError.networkConnectionError)
                }

                let syncModel = realm.resolve(syncModelRef)!
                try! realm.write {
                    syncModel.deleteLock = Date.distantPast
                }
            }
        }
    }
}
