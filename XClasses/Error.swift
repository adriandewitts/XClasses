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
    case noAccountError
    case expiredAccountError
    case syncLockError
    case microphonePermissionError
    case emptyField
    case databaseError

    public var errorDescription: String? {
        switch self {
        case .networkConnectionError:
            return NSLocalizedString("There is a problem with the internet connection.", comment: "")
        case .miscellaneousNetworkError:
            return NSLocalizedString("Something went wrong. Sorry.", comment: "")
        case .authenticationError:
            return NSLocalizedString("There was a problem logging in.", comment: "")
        case .unexpectedError:
            return NSLocalizedString("There was an unexpected problem.", comment: "")
        case .timeoutError:
            return NSLocalizedString("This is taking too long. We have stopped.", comment: "")
        case .permissionError:
            return NSLocalizedString("You do not have access.", comment: "")
        case .noAccountError:
            return NSLocalizedString("The account does not exist. Please try again with a different account.", comment: "")
        case .expiredAccountError:
            return NSLocalizedString("The account has expired.", comment: "")
        case .syncLockError:
            return NSLocalizedString("Please wait a little while before trying again.", comment: "")
        case .microphonePermissionError:
            let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
            return NSLocalizedString("\(appName) needs the microphone to work. Go to the Settings app and select \(appName). Then turn on the Microphone.", comment: "")
        case .emptyField:
            return NSLocalizedString("Field is empty.", comment: "")
        case .databaseError:
            return NSLocalizedString("Realm has failed", comment: "")
        }
    }
}

func log(error: String, file: String = #file, function: String = #function, line: Int = #line) {
    let fileName = file.split(separator: "/").last?.split(separator: ".").first ?? "Unknown"
    let crashlyticsError = NSError(domain: "iOS.\(fileName).\(function)", code: line, userInfo: ["description": error])
    Crashlytics.sharedInstance().recordError(crashlyticsError)

    print("*** \(error) Called from \(function) \(file): \(line)")
}

protocol AlertDelegate {
    func presentErrorAlert(error: Error, image: UIImage?, completion: (() -> Void)?)
    func presentAlert(title: String, image: UIImage?, cancel: Bool, completion: (() -> Void)?)
}

extension AlertDelegate {
    func presentErrorAlert(error: Error, image: UIImage? = nil, completion: (() -> Void)? = nil) {
        presentAlert(title: error.localizedDescription, image: image, cancel: false) {
            completion?()
        }
    }

    func presentAlert(title: String, image: UIImage? = nil, cancel: Bool = false, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)

        if let image = image {
            let uiImageAlertAction = UIAlertAction(title: "", style: .default, handler: nil)
            uiImageAlertAction.setValue(image.withRenderingMode(.alwaysOriginal), forKey: "image")
            alert.addAction(uiImageAlertAction)
        }

        if cancel {
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default))
        }

        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { action in
            completion?()
        }
        alert.addAction(okAction)

        if let viewController = self as? UIViewController {
            viewController.present(alert, animated: true)
        }
    }
}

//let uiAlertControl = UIAlertController(title: "Photo", message: "Photo of the Day", preferredStyle: .alert)
//
//
//let uiImageAlertAction = UIAlertAction(title: "", style: .default, handler: nil)
//let image = #imageLiteral(resourceName: "StockSnap_AWEH8SQCHN")
//
//// size the image
//let maxsize =  CGSize(width: 245, height: 300)
//
//let scaleSze = CGSize(width: 245, height: 245/image.size.width*image.size.height)
//let reSizedImage = image.resize(newSize: scaleSze)
//
//uiImageAlertAction.setValue(reSizedImage.withRenderingMode(.alwaysOriginal), forKey: "image")
//uiAlertControl.addAction(uiImageAlertAction)
//
//uiAlertControl.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//self.present(uiAlertControl, animated: true, completion: nil)

