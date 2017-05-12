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
}

public class ViewModel: Object, ViewModelDelegate
{
    var _index: Int = 0 // Position on current list in memory
    dynamic var _sync = SyncStatus.created.rawValue // Record status for syncing
    dynamic var id = 0 // Server ID - do not make primary key, as it gets locked
    dynamic var clientId = UUID().uuidString // Used to make sure records arent saved to the server DB multiple times

    // Mark: These are for overriding

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

    // End of overrides

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
                        FIRAnalytics.logEvent(withName: "iOS Error", parameters: ["error": "Property type does not exist" as NSObject])
                    }
                }
            }

            if isNew
            {
                realm.add(self)
            }
        }
    }
}
