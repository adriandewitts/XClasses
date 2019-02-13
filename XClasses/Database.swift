//
//  RealmHelper.swift
//  Bookbot
//
//  Created by Adrian on 11/2/18.
//  Copyright © 2018 Bookbot. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

/// The Database class has convenience functions for dealing with Realm. Realm will be removed in future.
class Database {
    /// Check that Realm is available, otherwise log any exceptions. This saves having to do exception handling throughout code.
    class var realm: Realm? {
        do {
            return try Realm()
        }
        catch {
            log(error: error.localizedDescription)
        }
        return nil
    }

    /// Will return all objects of model Type that are not _deleted. **Warning** Do not use if your model type is stored in a variable - it will return an empty result.
    class func objects<T: ViewModel>(_ model: T.Type) -> Results<T> {
        return realm!.objects(T.self).filter("_deleted = false")
    }

    /// Add object model to database.
    class func add(_ object: Object) {
        guard let realm = realm else {
            return
        }

        do {
            try realm.write {
                realm.add(object)
            }
        }
        catch {
            log(error: error.localizedDescription)
        }
    }

    /// Add multiple objects to database.
    class func add<S: Sequence>(_ objects: S) where S.Iterator.Element: Object {
        guard let realm = realm else {
            return
        }

        do {
            try realm.write {
                realm.add(objects)
            }
        }
        catch {
            log(error: error.localizedDescription)
        }
    }

    // TODO: be able to sync update objects in a collection (like List or Array)
    /// Update objects, as well as the sync status to be updated on that object. Will be uploaded when explicity synced.
    class func update(_ object: Any? = nil, block: ()->()) {
        guard let realm = realm else {
            return
        }

        do {
            try realm.write {
                block()

                if let object = object as? ViewModel {
                    object._sync = SyncStatus.updated.rawValue
                }
            }
        }
        catch {
            log(error: error.localizedDescription)
        }
    }

    // TODO: Set the sync for deletes
    /// Delete objects
    class func delete(_ object: ViewModel, local: Bool = false) {
        guard let realm = realm else {
            return
        }

        do {
            try realm.write {
                if local {
                    realm.delete(object)
                }
                else {
                    object._deleted = true
                    object._sync = SyncStatus.deleted.rawValue
                }
            }
        }
        catch {
            log(error: error.localizedDescription)
        }
    }

    /// Delete multiple objects
    class func delete<S: Sequence>(_ objects: S, local: Bool = false) where S.Iterator.Element: ViewModel {
        guard let realm = realm else {
            return
        }

        do {
            try realm.write {
                if local {
                    realm.delete(objects)
                }
                else {
                    for object in objects {
                        object._deleted = true
                    }
                }
            }
        }
        catch {
            log(error: error.localizedDescription)
        }
    }
}

/// A RealmString is required so you can have an array of strings in Realm (the string needs to be encapsulated in an object).
class RealmString: Object {
    @objc dynamic var stringValue = ""

    class func findOrCreate(_ stringValue: String, writeTransaction: Bool = true) -> RealmString {
        if let previousRealmString = Database.realm?.objects(RealmString.self).filter("stringValue = %@", stringValue).first {
            return previousRealmString
        }

        let newString = RealmString(stringValue: stringValue)
        if writeTransaction {
            Database.add(newString)
        }
        else {
            Database.realm?.add(newString)
        }

        return newString
    }

    init(stringValue: String) {
        super.init()
        self.stringValue = stringValue
    }

    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }

    required init() {
        super.init()
    }

    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
}
