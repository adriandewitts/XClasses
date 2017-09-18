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

enum CommonError: Error {
    case networkConnectionError
    case miscellaneousNetworkError

    var localizedDescription: String {
        switch self {
        case .networkConnectionError:
            return NSLocalizedString("The internet is not working.", comment: "")
        case .miscellaneousNetworkError:
            return NSLocalizedString("Something went wrong. Sorry.", comment: "")
        }
    }
}

extension UIViewController {
    func presentAlert(error: Error) {
        let alert = UIAlertController(title: NSLocalizedString("Alert", comment: "Title to alert user of problem"), message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .`default`))
        self.present(alert, animated: true) {
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

    print("\(error) called from \(function) \(file):\(line)")
}
