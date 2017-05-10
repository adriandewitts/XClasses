//
//  OpinionatedModel.swift
//  Sprite
//
//  Created by Adrian on 8/09/2016.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import Foundation
import RealmSwift

protocol ViewModelDelegate
{
    var _index: Int { get set }
    static func table() -> String
    static func tableVersion() -> Float
    static func tableView() -> String
    static func readOnly() -> Bool
    func properties() -> [String: String]
    func relatedCollection() -> [ViewModelDelegate]
    func syncProperties() -> [String: String]
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
        return ["_sync"]
    }

    static func table() -> String
    {
        return String(describing: self)
    }

    static func tableVersion() -> Float
    {
        return 1.0
    }

    static func tableView() -> String
    {
        return "default"
    }

    static func readOnly() -> Bool
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

    func syncProperties() -> [String: String]
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss'.'SSS"
        formatter.timeZone = TimeZone(abbreviation: "UTC")

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
                    properties[name] = formatter.string(from: value as! Date)
                }
            }
        }

        if self.id == 0
        {
            properties["id"] = ""
        }

        return properties
    }
}
