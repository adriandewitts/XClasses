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
    var headers: [String : String]? {
        return ["Content-type": "application/csv"]
    }

    var baseURL: URL {
        return SyncConfiguration.baseURL
    }

    var path: String {
        switch self {
            case .read(let version, let table, let view, _, _, _), .createAndUpdate(let version, let table, let view, _, _), .delete(let version, let table, let view, _, _):
                return "/\(version)/\(table)/\(view)"
        }
    }

    var method: Moya.Method {
        switch self {
            case .read:
                return .get
            case .createAndUpdate:
                return .post
            case .delete:
                return .delete
        }
    }

    var task: Task {
        switch self {
            case .read(_, _, _, let accessToken, let lastTimestamp, let predicate):
                var dict: [String: String] = [:]
                if accessToken != nil {
                    dict["access_token"] = accessToken
                }
                if let lastTimestamp = lastTimestamp {
                    dict["last_timestamp"] = lastTimestamp.toUTCString()
                }
                if predicate != nil {
                    dict["predicate"] = predicate
                }
                return .requestParameters(parameters: dict, encoding: URLEncoding.queryString)
            case .createAndUpdate(_, _, _, let accessToken, let records), .delete(_, _, _, let accessToken, let records):
                return .requestParameters(parameters: ["access_token": accessToken, "records": records], encoding: PipeEncoding.default)
        }
    }

    var sampleData: Data {
        return Data()
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

        // Change to a GET temporarily and then change back, to get the URL encoded
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
                if let i = value.index(of: "|")
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

        return urlRequest
    }
}
