//
//  Foundation+.swift
//  XClasses
//
//  Created by Adrian on 13/10/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import Foundation
// TODO: To be updated and reworked

extension String {
    func snakeCased() -> String {
        let pattern = "([a-z0-9])([A-Z])"

        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: self.count)
        return (regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2").lowercased())!
    }

    // TODO: Remove -> Swifter Swift does this
    func camelCased() -> String {
        let items = components(separatedBy: "_")
        var camelCase = ""

        items.enumerated().forEach {
            camelCase += 0 == $0 ? $1 : $1.capitalized
        }
        return camelCase
    }

    func removedCharacters(with forbiddenChars: CharacterSet) -> String {
        let passed = self.unicodeScalars.filter { !forbiddenChars.contains($0) }
        return String(String.UnicodeScalarView(passed))
    }

    func removedCharacters(with: String) -> String {
        return removedCharacters(with: CharacterSet(charactersIn: with))
    }
}

extension Date {
    func toUTCString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss'.'SSS"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: self)
    }

    static func from(UTCString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss'.'SSS"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.date(from: UTCString)
    }
}

extension Collection {
    // Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

//TODO: This needs to be fixed up to make clear the path, urlstring, and url

extension String {
    func toURLString() -> String {
        if hasPrefix("/") || hasPrefix("http://") {
            return escape()
        }

        if let urlString = Bundle.main.path(forResource: self, ofType: nil) {
            return urlString.escape()
        }

        // TODO: Look for resource in user folder

        if let urlString = Bundle.main.path(forResource: "default", ofType: "png") {
            return urlString.escape()
        }

        return "/"
    }

    func toURL() -> URL {
        var urlString = toURLString()
        if hasPrefix("/") {
            urlString = "file:/\(urlString)"
        }
        return URL(string: urlString)!
    }

    func escape() -> String {
        return addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    }
    
    /// Get all the ranges of the substring that matched in the string
    func ranges(of substring: String, options: CompareOptions = [], locale: Locale? = nil) -> [Range<Index>] {
        var ranges: [Range<Index>] = []
        while ranges.last.map({ $0.upperBound < self.endIndex }) ?? true,
            let range = self.range(of: substring, options: options, range: (ranges.last?.upperBound ?? self.startIndex)..<self.endIndex, locale: locale)
        {
            ranges.append(range)
        }
        
        return ranges
    }
}

class MutatingURL {
    var url: URL

    init(url: URL) {
        self.url = url
    }
}

extension Data {
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        }
        else {
            try write(to: fileURL, options: .atomic)
        }
    }
}
