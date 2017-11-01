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
            return NSLocalizedString("We are not connected to the internet.", comment: "")
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
            return NSLocalizedString("Please wait.", comment: "")
        }
    }
}

extension UIViewController {
    func presentAlert(error: Error) {
        let alert = UIAlertController(title: NSLocalizedString("Alert", comment: "Title to alert user of problem"), message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .`default`))
        present(alert, animated: true) {
            self.alertAction()
        }
    }

    /// To override and complete actions after alert is presented
    func alertAction() { }
}

func log(error: String, file: String = #file, function: String = #function, line: Int = #line) {
    if Device.isDevice {
        Analytics.logEvent("iOS Error", parameters: ["error": error as NSObject, "file": file as NSObject, "function": function as NSObject, "line": line as NSObject])
    }

    print("*** \(error) called from \(function) \(file):\(line)")
}
