//
//  Foundation+.swift
//  XClasses
//
//  Created by Adrian on 13/10/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import Foundation

// Need a String convenience method to load from either a local path or external url
// Need a URL method to do the above as well

extension Bundle
{
    class func resource(path: String) -> String?
    {
        do
        {
            let path = Bundle.main.path(forResource: path, ofType: nil)!
            return try String(contentsOfFile: path)
        }
        catch { return nil }
    }
}
