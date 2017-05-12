//
//  WebService.swift
//  Bookbot
//
//  Created by Adrian on 1/5/17.
//  Copyright © 2017 Adrian DeWitts. All rights reserved.
//

import Foundation
import Moya
import Alamofire

enum WebService
{
    case read(version: Float, table: String, view: String, accessToken: String?, lastTimestamp: Date?, predicate: String?)
    case createAndUpdate(version: Float, table: String, view: String, accessToken: String, records: [ViewModel])
    case delete(version: Float, table: String, view: String, accessToken: String, records: [ViewModel])
}

extension WebService: TargetType
{
    //var baseURL: URL { return URL(string: "https://web-services-dot-bookbot-162503.appspot.com")! }
    var baseURL: URL { return URL(string: "http://localhost:8080")! }


    var path: String
    {
        switch self
        {
            case .read(let version, let table, let view, _, _, _), .createAndUpdate(let version, let table, let view, _, _), .delete(let version, let table, let view, _, _):
                return "/\(version)/\(table)/\(view)"
        }
    }

    var method: Moya.Method
    {
        switch self
        {
            case .read:
                return .get
            case .createAndUpdate:
                return .post
            case .delete:
                return .delete
        }
    }

    var parameters: [String: Any]?
    {
        switch self
        {
            case .read(_, _, _, let accessToken?, let lastTimestamp?, let predicate?):
                return ["access_token": accessToken, "last_timestamp": lastTimestamp, "predicate": predicate]
            case .createAndUpdate(_, _, _, let accessToken, let records), .delete(_, _, _, let accessToken, let records):
                return ["access_token": accessToken, "records": records]
            default:
                return [:]
        }
    }

    var parameterEncoding: ParameterEncoding
    {
        switch self
        {
            case .read:
                return URLEncoding.default
            case .createAndUpdate, .delete:
                return PipeEncoding.default
        }
    }

    var sampleData: Data { return Data() }

    var task: Task
    {
        switch self
        {
            case .read, .createAndUpdate, .delete:
                return .request
        }
    }
}

struct PipeEncoding: ParameterEncoding
{
    public static var `default`: PipeEncoding { return PipeEncoding() }

    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest
    {
        var urlRequest = try urlRequest.asURLRequest()
        guard var parameters = parameters else { return urlRequest }
        let records = parameters.removeValue(forKey: "records") as! Array<ViewModel>

        // Change to a GET temporarily and then change back to get the URL encoded
        let temp = urlRequest.httpMethod
        urlRequest.httpMethod = "GET"
        urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        urlRequest.httpMethod = temp

        var lines = [String]()
        let propertyNames = records[0].exportProperties().keys
        lines.append(propertyNames.joined(separator: "|"))

        for record in records
        {
            let properties = record.exportProperties()
            var elements = [String]()
            for propertyName in propertyNames
            {
                var value = properties[propertyName]!
                if let i = value.characters.index(of: "|")
                {
                    value.remove(at: i)
                }
                elements.append(value)
            }
            lines.append(elements.joined(separator: "|"))
        }

        urlRequest.httpBody = lines.joined(separator: "\n").data(using: .utf8)

        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil
        {
            urlRequest.setValue("application/pipe", forHTTPHeaderField: "Content-Type")
        }

//        print("*******************")
//        print(urlRequest)
//        print(lines.joined(separator: "\n"))

        return urlRequest
    }
}
