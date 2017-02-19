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
    func properties() -> [String: String]
    func relatedCollection() -> [ViewModelDelegate]
}

class RealmString: Object
{
    dynamic var stringValue = ""
}

public class ViewModel: Object, ViewModelDelegate
{
    dynamic var id = UUID().uuidString
    dynamic var createdAt = NSDate()
    dynamic var updatedAt = NSDate()
    dynamic var deletedAt = NSDate()
    
    override public static func primaryKey() -> String?
    {
        return "id"
    }

    func properties() -> [String: String]
    {
        return ["title": "Placeholder", "path": "/", "image": "default.png"]
    }

    func relatedCollection() -> [ViewModelDelegate]
    {
        return [ViewModel()]
    }
}
