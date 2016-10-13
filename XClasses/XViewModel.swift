//
//  OpinionatedModel.swift
//  Sprite
//
//  Created by Adrian on 8/09/2016.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import Foundation
import RealmSwift

class RealmString: Object
{
    dynamic var stringValue = ""
}

class XViewModel : Object
{
    dynamic var id = UUID().uuidString
    dynamic var createdAt = NSDate()
    dynamic var updatedAt = NSDate()
    
    override static func primaryKey() -> String?
    {
        return "id"
    }
    
    func properties() -> [String: String]
    {
        return ["title": "Placeholder", "path": "define the app path", "image": "find a default"]
    }
}
