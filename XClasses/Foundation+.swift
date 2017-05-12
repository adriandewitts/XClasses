//
//  Foundation+.swift
//  XClasses
//
//  Created by Adrian on 13/10/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import Foundation

extension String
{
    func snakeCase() -> String
    {
        let pattern = "([a-z0-9])([A-Z])"

        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: self.characters.count)
        return (regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2").lowercased())!
    }

    func camelCase() -> String
    {
        let items = self.components(separatedBy: "_")
        var camelCase = ""

        items.enumerated().forEach
        {
            camelCase += 0 == $0 ? $1 : $1.capitalized
        }
        return camelCase
    }
}

extension Date
{
    func toUTCString() -> String
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss'.'SSS"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: self)
    }

    static func from(UTCString: String) -> Date?
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss'.'SSS"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.date(from: UTCString)
    }
}

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

        if let urlString = Bundle.main.path(forResource: self, ofType: nil)
        {
            let escaped = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            return "file://\(escaped)"
        }

        if let urlString = Bundle.main.path(forResource: "default", ofType: "png")
        {
            let escaped = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            return "file://\(escaped)"
        }

        return "file://"
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
