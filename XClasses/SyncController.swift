//
//  SyncController.swift
//  Bookbot
//
//  Created by Adrian on 29/4/17.
//  Copyright © 2017 Adrian DeWitts. All rights reserved.
//

import Foundation
import RealmSwift
import Moya

protocol SyncControllerDelegate
{
    func belatedResponse(response: [ViewModel], error: String)
}

public class SyncModel: Object
{
    dynamic var modelName = ""
    //dynamic var localSync: NSDate? = nil // Last time local changes were synced
    dynamic var serverSync: NSDate? = nil // Server timestamp of last server sync. To be used on next sync request
}

public class SyncController
{
    static let sharedInstance = SyncController()
    var controllers = [String:String]()

    func sync(models: [String])
    {
        //Alamofire.SessionManager.default.session.configuration.timeoutIntervalForRequest = 60
        let realm = try! Realm()
        var syncModels = [SyncModel]()

        if models.count > 0
        {
            for model in models
            {
                let result = realm.objects(SyncModel.self).filter("modelName = '\(model)'")
                if result.count > 0
                {
                    syncModels.append(result[0])
                }
                else
                {
                    syncModels.append(SyncModel(value: ["modelName": model]))
                }
            }
        }
        else
        {
            syncModels = Array(realm.objects(SyncModel.self))
        }

        for model in syncModels
        {
//            let requestURL = "https://web-services-dot-bookbot-162503.appspot.com/\(self.version)/\(model.modelName)/default"
//            print(requestURL)
//            Alamofire.request(requestURL).validate().responseString { response in
//                print("Success: \(response.result.isSuccess)")
//                print("Response String: \(response.result.value)")
//            }

            let provider = MoyaProvider<WebService>()
            let homophone = Homophone()
            homophone.homophone = "their, there"
            provider.request(.createAndUpdate(version: 1.0, table: model.modelName, view: "default", accessToken: "placeholder-access", records: [homophone]))
            { result in
                print("-------------------------")
                print(result)
                print("-------------------------")
            }
            // GET data on model
            // POST/PUT/DELETE models
            // Handle retries
        }
    }

    func query(model: String, query: NSPredicate, order: String, controller: SyncControllerDelegate) -> ([ViewModel], String)
    {

        // Data is fresh - respond from DB
        // Data is not fresh - sync with server
        return ([ViewModel()], "")
    }

    private func saveToDB(response: String)
    {
        // Iterate through data and save
    }
}



// Sync manager request - is DB ready (updated in last 24 hours - set period)? yes respond immediately. no, if first time wait for response (also display error if no network, or there is a problem). no wait 3 second for response, then respond. if response earlier, display.
// Sync manager (sync only) - first time/on app open, immediate change (silent push or record update on client from controller)
//
// Config per model
// Removal - periodically - when a certain age, only when deleted
// File upload - immediately, triggered
// Table name, view name (methods)
// Allowed last sync (Freshness) - 24 hours (periodic), has to be fresh
// Needs authentication


// Sync tables: all, user_space.
// Search - out of the userspace scope would user a different view server side, and a different DB (same model on the client side) -- use a different method
