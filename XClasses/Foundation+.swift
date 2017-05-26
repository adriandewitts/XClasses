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

//TODO: This needs to be fixed up to make clear the path, urlstring, and url

extension String
{
    func toURLString() -> String
    {
        if self.hasPrefix("/") || self.hasPrefix("http://")
        {
            return self.escape()
        }

        if let urlString = Bundle.main.path(forResource: self, ofType: nil)
        {
            return urlString.escape()
        }

        // TODO: Look for resource in user folder

        if let urlString = Bundle.main.path(forResource: "default", ofType: "png")
        {
            return urlString.escape()
        }

        return "/"
    }

    func toURL() -> URL
    {
        var urlString = self.toURLString()
        if self.hasPrefix("/")
        {
            urlString = "file:/\(urlString)"
        }
        return URL(string: urlString)!
    }

    func escape() -> String
    {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    }
}

