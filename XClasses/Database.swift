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

/// The Database class has convenience functions which check that Realm works and then logs any exceptions. This saves having to do exception handling throughout the code base.
/// This covers
class Database {
    class var realm: Realm? {
        do {
            return try Realm()
        }
        catch {
            log(error: error.localizedDescription)
        }
        return nil
    }

    /// Warning: Do not use if your model is stored in a variable when calling this - it will return an empty result
    class func objects<T: ViewModel>(_ model: T.Type) -> Results<T> {
        return realm!.objects(T.self).filter("_deleted = false")
    }

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
    class func delete(_ object: Object) {
        guard let realm = realm else {
            return
        }

        do {
            try realm.write {
                realm.delete(object)
            }
        }
        catch {
            log(error: error.localizedDescription)
        }
    }

    class func delete<S: Sequence>(_ objects: S) where S.Iterator.Element: Object {
        guard let realm = realm else {
            return
        }

        do {
            try realm.write {
                realm.delete(objects)
            }
        }
        catch {
            log(error: error.localizedDescription)
        }
    }
}


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
