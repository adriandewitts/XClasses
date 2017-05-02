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
    func properties() -> [String: String]
    func relatedCollection() -> [ViewModelDelegate]
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
    dynamic var _sync = SyncStatus.current.rawValue // Record status for syncing

    dynamic var id = 0 // Server ID
    dynamic var updatedAt = Date()

    // Mark: These are for overriding
    
//    override public static func primaryKey() -> String?
//    {
//        return "_id"
//    }

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
