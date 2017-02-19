//
//  Foundation+.swift
//  XClasses
//
//  Created by Adrian on 13/10/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import Foundation

extension Bundle
{
    class func contents(fileName: String) -> String?
    {
        do
        {
            return try String(contentsOfFile: Bundle.main.path(forResource: fileName, ofType: nil)!)
        }
        catch { return nil }
    }
}

extension String
{
    func toURLString() -> String
    {
        if self.hasPrefix("/")
        {
            return "file://\(self)"
        }
        if self.hasPrefix("http://")
        {
            return self
        }

        if let URLString = Bundle.main.path(forResource: self, ofType: nil)
        {
            let escaped = URLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            return "file://\(escaped)"
        }

        return "file://\(Bundle.main.path(forResource: "default", ofType: "png")!)"
    }

    func toURL() -> URL
    {
        let escaped = self.toURLString()
        return URL(string: escaped)!
    }

    func toContents() -> String
    {
        // Will need to do checks and return nothing if needs be
        return try! String(contentsOfFile: self.toURLString())
    }

//    func toData()
//    {
//        return try! Data(contentsOf: self.toURL())
//    }
}

// String - file path, web url, file bundle
// input: String, URL
// output: String path, URL, string contents, data
// string to string, string to URL, string to contents, string to data, url to contents, url to data
