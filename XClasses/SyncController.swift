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

public class SyncModel: Object
{
    dynamic var modelName = ""
    dynamic var serverSync = Date.distantPast // Server timestamp of last server sync. To be used on next sync request
    dynamic var readLock = Date.distantPast
    dynamic var writeLock = Date.distantPast
}

public class SyncController
{
    static let sharedInstance = SyncController()
    static let serverTimeout = 60.0
    var uid = ""

    func configure(models: [AnyClass])
    {
        let realm = try! Realm()

        for m in models
        {
            let model = "\(m)"

            if realm.objects(SyncModel.self).filter("modelName = '\(model)'").count == 0
            {
                try! realm.write { realm.add(SyncModel(value: ["modelName": model])) }
            }
        }
    }

    func configureFile(models: [AnyClass])
    {
        for m in models
        {
            let model = m as! ViewModel.Type
            let paths = model.fileAttributes
            for p in paths
            {
                let path = Path(p.value.localURL).parent
                if !path.exists
                {
                    try! path.createDirectory()
                }
            }

        }
    }

    func sync(models: [AnyClass])
    {
        // TODO: Background the sync and sleep each request for 3 seconds
        let user = Auth.auth().currentUser
        if let user = user
        {
            uid = user.uid
            user.getIDToken() {
                token, error in
                if let error = error
                {
                    print(error)
                    return
                }

                self.writeSync(models: models, token: token!)
                self.readSync(models: models, token: token!, completion: {})
            }
        }
        else
        {
            readSync(models: models, token: "", completion: {})
        }
    }

    //TODO: Completion handler
    func writeSync(models: [AnyClass], token: String)
    {
        let realm = try! Realm()
        let provider = MoyaProvider<WebService>()

        for m in models
        {
            let modelClass = m as! ViewModel.Type
            let model = "\(m)"
            // This section handles the writes to server DB
            // Check if class is read only, has a writelock (max 1 minute), and has something to write
            if modelClass.readOnly == false
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
                                    catch { E.log(error: "From writeSync: Response was impossibly incorrect", from: self) }
                                }
                                else
                                {
                                    // TODO: if 403 show login modal
                                    E.log(error: "Server returned status code \(moyaResponse.statusCode)", from: self)
                                    Timer.scheduledTimer(withTimeInterval: SyncController.serverTimeout, repeats: false, block: { timer in self.sync(models: models)})
                                }
                            case let .failure(error):
                                // TODO: If timer exists don't schedule another timer
                                E.log(error: error, from: self)
                                Timer.scheduledTimer(withTimeInterval: SyncController.serverTimeout, repeats: false, block: { timer in self.sync(models: models)})
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
                                        E.log(error: "Either user was trying to delete records they can't or something went wrong with the server")
                                    }
                                case let .failure(error):
                                    E.log(error: error)
                                    Timer.scheduledTimer(withTimeInterval: SyncController.serverTimeout, repeats: false, block: { timer in self.sync(models: models)})
                                }
                                //try! realm.write { syncModel.writeLock = Date.distantPast }
                                // TODO: Update and delete would both need to finish to release (At the moment keeping them commented out so it locks for a min
                            }
                        }
                    }
                }
            }
        }
    }

    func readSync(models: [AnyClass], token: String, completion: () -> Void)
    {
        let realm = try! Realm()
        let provider = MoyaProvider<WebService>()//(plugins: [NetworkLoggerPlugin(verbose: true)])

        for m in models
        {
            let modelClass = m as! ViewModel.Type
            let model = "\(m)"

            let minuteAgo = Date.init(timeIntervalSinceNow: -SyncController.serverTimeout)
            var predicate = NSPredicate(format: "modelName = '\(model)' AND readLock < %@", minuteAgo as CVarArg)
            if let syncModel = realm.objects(SyncModel.self).filter(predicate).first
            {
                var timestamp = Date.distantPast
                try! realm.write { syncModel.readLock = Date() }

                provider.request(.read(version: modelClass.tableVersion, table: modelClass.table, view: modelClass.tableView, accessToken: token, lastTimestamp: syncModel.serverSync, predicate: nil))
                { result in
                    switch result {
                    case let .success(moyaResponse):
                        if moyaResponse.statusCode == 200
                        {
                            do
                            {
                                let response = try moyaResponse.mapString()
                                let l = response.components(separatedBy: "\n")
                                let meta = l[0].components(separatedBy: "|")
                                timestamp = Date.from(UTCString: meta[1])!
                                let h = l[1].components(separatedBy: "|")
                                let header = h.map { $0.camelCase() }
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

                                    let records = realm.objects(modelClass).filter(predicate)
                                    if (dict["delete"] == nil) || (dict["delete"] != "true")
                                    {
                                        if records.count > 0
                                        {
                                            records.first!.importProperties(dictionary: dict, isNew:false)
                                        }
                                        else
                                        {
                                            let record = modelClass.init()
                                            record.importProperties(dictionary: dict, isNew: true)
                                        }
                                    }
                                    else
                                    {
                                        try! realm.write {
                                            realm.delete(records.first!)
                                        }
                                    }
                                }
                            }
                            catch { E.log(error: "Response was impossibly incorrect") }
                        }
                        else
                        {
                            // TODO: if 403 show login modal
                            E.log(error: "Server returned status code \(moyaResponse.statusCode)")
                            Timer.scheduledTimer(withTimeInterval: SyncController.serverTimeout, repeats: false, block: { timer in self.sync(models: models)})
                        }
                    case let .failure(error):
                        E.log(error: "Server connectivity error\(error)")
                        Timer.scheduledTimer(withTimeInterval: SyncController.serverTimeout, repeats: false, block: { timer in self.sync(models: models)})
                    }

                    try! realm.write {
                        syncModel.readLock = Date.distantPast
                        syncModel.serverSync = timestamp
                    }
                    // TODO Run completion here
                }
            }
        }
    }

    // TODO: fix query to have completion handler
    func query(model: AnyClass, query: NSPredicate, order: String, orderAscending: Bool, freshness: Double = 3600) -> (Results<Object>, String?)
    {
        let realm = try! Realm()
        let result = realm.objects(model as! Object.Type).filter(query).sorted(byKeyPath: order, ascending: orderAscending)

        let predicate = NSPredicate(format: "modelName = '\(model)'")
        if let syncModel = realm.objects(SyncModel.self).filter(predicate).first
        {
            // TODO: Is Fresh if push notifcations are on
            let interval = syncModel.serverSync.timeIntervalSince(Date())
            // If results are fresh send it back - that's it
            if interval < freshness
            {
                return (result, nil)
            }
            else
            {
                var timer: Timer?
                // If there is already content, lets fix the time to max 3 seconds to find anything new. Otherwise wait until we do get something back.
                if result.count > 0
                {
                    timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false, block: { timer in self.checkin(model: model, query: query, order: order, orderAscending: orderAscending)})
                }

                // Once data is synced, invalidate timer if needed and then send data back
                // TODO: run completion handler
                readSync(model: model, completion: {
                    if let timer = timer
                    {
                        if timer.isValid { timer.invalidate() }
                    }
                    self.checkin(model: model, query: query, order: order, orderAscending: orderAscending)
                })

            }
        }

        return (result, "checkin")
    }

    func readSync(model: AnyClass, completion: @escaping () -> Void)
    {
        let user = Auth.auth().currentUser
        if let user = user
        {
            uid = user.uid
            user.getIDToken() {
                token, error in
                if error != nil { return }
                self.readSync(models: [model], token: token!, completion: completion)
            }
        }
        else { readSync(models: [model], token: "", completion: completion) }
    }

    func checkin(model: AnyClass, query: NSPredicate, order: String, orderAscending: Bool)
    {
        let realm = try! Realm()
        let predicate = NSPredicate(format: "modelName = '\(model)'")
        if let syncModel = realm.objects(SyncModel.self).filter(predicate).first
        {
            // If it is still waiting for the response - dont wait any more and send back the results. 
            var error: String?
            if syncModel.readLock.timeIntervalSince(Date()) < 3.0
            {
                error = "Not reachable" // Not connected at this time
            }

            let result = realm.objects(model as! Object.Type).filter(query).sorted(byKeyPath: order, ascending: orderAscending)
            // TODO: Create completion handler
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


    // TODO: will search on server and cache these queries in a different Realm DB
    // func directQuery(model: AnyClass, query: NSPredicate, order: String, controller: SyncControllerDelegate, freshness: Int = 3600) -> ([ViewModel], String)
}

public class E
{
    static func log(error: Any, from: Any? = nil)
    {
        //TODO: setup errors to go to Fabric
        //FirebaseCrash.log("iOS Sync Error: \(error)");
        print(error)
    }
}
