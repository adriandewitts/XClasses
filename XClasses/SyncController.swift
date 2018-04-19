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
    @objc dynamic var serverSync: Date? = nil // Server timestamp of last server sync. To be used on next sync request
    @objc dynamic var readLock = Date.distantPast
    @objc dynamic var writeLock = Date.distantPast
    @objc dynamic var deleteLock = Date.distantPast
    @objc dynamic var internalVersion = 1.0

    class func named(_ model: String) -> SyncModel? {
        guard let realm = getRealm() else {
            return nil
        }
        return realm.objects(SyncModel.self).filter(NSPredicate(format: "modelName = '\(model)'")).first
    }
}

public class SyncController
{
    static let sharedInstance = SyncController()
    static let serverTimeout = 60.0
    static let retries = 60
    static let retrySleep: UInt32 = 1
    var uid = ""

    /// Configure sets up the meta data for each synced table
    func configure(models: [ViewModel.Type]) {
        // Looking for a Realm Configuration in a separate Migrator class which is defined outside of the library
        var config = Migrator.configuration
        config.fileURL = (Path.userApplicationSupport + "default.realm").url
        config.shouldCompactOnLaunch = { totalBytes, usedBytes in
            // Compact if the file is over 100MB in size and less than 50% 'used'
            let oneHundredMB = 100 * 1024 * 1024
            print("DB Size total: \(totalBytes) used: \(usedBytes)")
            return (totalBytes > oneHundredMB) && (Double(usedBytes) / Double(totalBytes)) < 0.5
        }
        Realm.Configuration.defaultConfiguration = config

        // New Synmodel if it does not exist
        for model in models {
            let name = "\(model)"
            if SyncModel.named(name) == nil {
                add(SyncModel(value: ["modelName": name, "internalVersion": model.internalVersion]))
            }
        }
    }

    /// Configure file will create needed folders to store synced files
    func configureFile(models: [ViewModel.Type]) {
        for model in models {
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
            autoreleasepool {
                // Get Sync Model (must be configured and ready)
                guard let syncModel = SyncModel.named("\(model)") else {
                    reject(CommonError.unexpectedError)
                    return
                }

                // Is the sync fresh and there is record, then resolve
                let serverSync = syncModel.serverSync ?? Date.distantPast
                let interval = serverSync.timeIntervalSince(Date())
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
    }

    /// Read sync will get token, and retry the sync
    //TODO: Retry if there is no new data
    func retrySync(model: ViewModel.Type) -> Promise<Void> {
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
            autoreleasepool {
                let modelClass = model
                let model = "\(model)"

                // Make sure model has permission
                let authenticated = (modelClass.authenticate == true && token != nil) || modelClass.authenticate == false
                guard authenticated, modelClass.read == true else {
                    reject(CommonError.permissionError)
                    return
                }

                // Get syncModel
                let minuteAgo = Date(timeIntervalSinceNow: -SyncController.serverTimeout)
                guard let syncModel = SyncModel.named(model), syncModel.readLock < minuteAgo else {
                    reject(CommonError.syncLockError)
                    return
                }

                // Make sync locked
                update {
                    syncModel.readLock = Date()
                }
                var timestamp = Date.distantPast

                // Make request with Moya
                let provider = MoyaProvider<WebService>(callbackQueue: DispatchQueue.global(qos: qos))//, plugins: [NetworkLoggerPlugin(verbose: true)])
                provider.request(.read(version: modelClass.tableVersion, table: modelClass.table, view: modelClass.tableView, accessToken: token, lastTimestamp: syncModel.serverSync, predicate: nil)) { result in
                    // Put autoreleasepool around everything to get all realms
                    autoreleasepool {
                        defer {
                            if let syncModel = SyncModel.named(model) {
                                update {
                                    syncModel.readLock = Date.distantPast
                                    syncModel.serverSync = timestamp
                                }
                            }
                        }

                        switch result {
                        case let .success(moyaResponse):
                            guard moyaResponse.statusCode == 200 else {
                                if moyaResponse.statusCode == 403 {
                                    SyncConfiguration.forbidden()
                                }
                                else {
                                    log(error: "Server returned status code \(moyaResponse.statusCode) while trying to read sync for \(model)")
                                }
                                reject(CommonError.permissionError)
                                return
                            }

                            do {
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

                                for line in lines {
                                    let components = line.components(separatedBy: "|")
                                    let id = components[idIndex]

                                    var dict = [String: String]()
                                    for (index, property) in header.enumerated() {
                                        dict[property] = components[index]
                                    }

                                    if let record = modelClass.find(NSPredicate(format: "id = \(id)")).first {
                                        update {
                                            if (dict["delete"] == nil) || (dict["delete"] != "true") {
                                                record.importProperties(dictionary: dict, isNew:false)
                                            }
                                            else {
                                                record._deleted = true
                                            }
                                        }
                                    }
                                    else {
                                        let record = modelClass.init()
                                        record.importProperties(dictionary: dict, isNew: true)
                                        newRecords.append(record)
                                    }
                                }
                                add(newRecords)
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
        }
    }

    func writeSync(model: ViewModel.Type, token: String? = nil, qos: DispatchQoS.QoSClass = .utility) -> Promise<Void> {
        return Promise<Void> { resolve, reject, _ in
            autoreleasepool {
                let modelClass = model
                let model = "\(model)"

                // Make sure model has permission. Writes/POST always must have authentication
                guard token != nil, modelClass.write == true else {
                    reject(CommonError.permissionError)
                    return
                }

                // Make sure there are records to save
                var predicate = NSPredicate(format: "_sync = \(SyncStatus.created.rawValue) OR _sync = \(SyncStatus.updated.rawValue)")
                let syncRecords = modelClass.find(predicate)
                guard syncRecords.count > 0 else {
                    return
                }

                // Make sure syncModel is not sync locked
                let minuteAgo = Date(timeIntervalSinceNow: -SyncController.serverTimeout)
                guard let syncModel = SyncModel.named(model), syncModel.writeLock < minuteAgo else {
                    reject(CommonError.syncLockError)
                    return
                }

                update {
                    syncModel.writeLock = Date()
                }

                // 1000 seems to get close to the 60 second limit for updates, so 500 gives it some room to breath
                let limit = 500
                var syncSlice: [ViewModel] = []
                syncSlice.reserveCapacity(limit)
                var count = 0
                for record in syncRecords {
                    count += 1
                    if count >= limit {
                        break
                    }
                    syncSlice.append(record)
                }

                let provider = MoyaProvider<WebService>(callbackQueue: DispatchQueue.global(qos: qos))//, plugins: [NetworkLoggerPlugin(verbose: true)])
                provider.request(.createAndUpdate(version: modelClass.tableVersion, table: modelClass.table, view: modelClass.tableView, accessToken: token!, records: syncSlice)) { result in
                    autoreleasepool {
                        defer {
                            if let syncModel = SyncModel.named(model) {
                                update {
                                    syncModel.writeLock = Date.distantPast
                                }
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
                                        let item = modelClass.find(predicate).first!
                                        update {
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
                            else if moyaResponse.statusCode == 403 {
                                SyncConfiguration.forbidden()
                                reject(CommonError.permissionError)
                            }
                            else {
                                log(error: "Server returned status code \(moyaResponse.statusCode) while trying to write sync for \(model).")
                                //print(try! moyaResponse.mapString())
                                reject(CommonError.permissionError)
                            }
                        case let .failure(error):
                            log(error: error.errorDescription!)
                            reject(CommonError.networkConnectionError)
                        }
                    }
                }
            }
        }
    }

    /// Warning deleteSync has not been used or tested
    func deleteSync(model: ViewModel.Type, token: String? = nil, qos: DispatchQoS.QoSClass = .utility) -> Promise<Void> {
        return Promise<Void> { resolve, reject, _ in
            autoreleasepool {
                let provider = MoyaProvider<WebService>(callbackQueue: DispatchQueue.global(qos: qos))//, plugins: [NetworkLoggerPlugin(verbose: true)])

                let modelClass = model
                let model = "\(model)"

                // Make sure there are records to delete
                let syncRecords = modelClass.find(NSPredicate(format: "_sync = \(SyncStatus.deleted.rawValue)"))
                guard syncRecords.count > 0 else {
                    return
                }

                // Make sure model is not sync locked
                let minuteAgo = Date.init(timeIntervalSinceNow: -SyncController.serverTimeout)
                guard let syncModel = SyncModel.named(model), syncModel.deleteLock < minuteAgo else {
                    reject(CommonError.syncLockError)
                    return
                }

                // Make sure model has permission. Delete always must have authentication
                guard token != nil, modelClass.write == true else {
                    reject(CommonError.permissionError)
                    return
                }

                //var timestamp = Date.distantPast
                update {
                    syncModel.deleteLock = Date()
                }

                let syncRecordsRef = ThreadSafeReference(to: syncRecords)

                provider.request(.delete(version: modelClass.tableVersion, table: modelClass.table, view: modelClass.tableView, accessToken: token!, records: Array(syncRecords))) { result in
                    autoreleasepool {
                        switch result {
                        case let .success(moyaResponse):
                            if moyaResponse.statusCode == 200 {
                                // As long as the status code is a success, we will delete these objects
                                if let syncRecords = getRealm()?.resolve(syncRecordsRef) {
                                    delete(syncRecords)
                                }
                            }
                            else if moyaResponse.statusCode == 403 {
                                SyncConfiguration.forbidden()
                                reject(CommonError.permissionError)
                            }
                            else {
                                log(error: "Either user was trying to delete records they can't or something went wrong with the server")
                                reject(CommonError.permissionError)
                            }
                        case let .failure(error):
                            log(error: error.errorDescription!)
                            reject(CommonError.networkConnectionError)
                        }

                        if let syncModel = SyncModel.named(model) {
                            update {
                                syncModel.deleteLock = Date.distantPast
                            }
                        }
                    }
                }
            }
        }
    }
}
