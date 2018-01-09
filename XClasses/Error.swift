//
//  Error.swift
//  Bookbot
//
//  Created by Adrian on 7/9/17.
//  Copyright © 2017 Bookbot. All rights reserved.
//

import Foundation
import Firebase
import AssistantKit

enum CommonError: LocalizedError {
    case networkConnectionError
    case miscellaneousNetworkError
    case authenticationError
    case unexpectedError
    case timeoutError
    case permissionError
    case syncLockError

    public var errorDescription: String? {
        switch self {
        case .networkConnectionError:
            return NSLocalizedString("There is a problem with the internet connection.", comment: "")
        case .miscellaneousNetworkError:
            return NSLocalizedString("Something went wrong. Sorry.", comment: "")
        case .authenticationError:
            return NSLocalizedString("There was a problem logging in.", comment: "")
        case .unexpectedError:
            return NSLocalizedString("There is an unexpected problem.", comment: "")
        case .timeoutError:
            return NSLocalizedString("This is taking too long. We have stopped.", comment: "")
        case .permissionError:
            return NSLocalizedString("You do not have access.", comment: "")
        case .syncLockError:
            return NSLocalizedString("Please wait a little while before trying again.", comment: "")
        }
    }
}

protocol AlertDelegate {
    func presentAlert(error: Error, completion: (() -> Void)?)
}

extension AlertDelegate {
    func presentAlert(error: Error, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: NSLocalizedString("Alert", comment: "Title to alert user of problem"), message: error.localizedDescription, preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { action in
            completion?()
        }
        alert.addAction(okAction)
        if let viewController = self as? UIViewController {
            viewController.present(alert, animated: true)
        }
    }
}

func log(error: String, file: String = #file, function: String = #function, line: Int = #line) {
    let fileName = file.split(separator: "/").last?.split(separator: ".").first ?? "Unknown"
    let crashlyticsError = NSError(domain: "iOS.\(fileName).\(function)", code: line, userInfo: ["description": error])
    Crashlytics.sharedInstance().recordError(crashlyticsError)

    print("*** \(error) Called from \(function) \(file): \(line)")
}
