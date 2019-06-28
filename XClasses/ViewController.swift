//
//  Extension.swift
//  Sprite
//
//  Created by Adrian on 5/09/2016.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit

/// A ViewController that manages ViewModels and keyboards.
class ViewController: UIViewController, ViewModelManagerDelegate, AlertDelegate {
    var viewModel: ViewModelDelegate!
    @IBOutlet var bottomConstraint: NSLayoutConstraint?

    required init?(coder aDecoder: NSCoder) {
        viewModel = FlowController.viewModel
        super.init(coder: aDecoder)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        updateConstraint(notification: notification)
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        updateConstraint(notification: notification)
    }

    func updateConstraint(notification: NSNotification) {
        if let bottomConstraint = bottomConstraint, let userInfo = notification.userInfo {
            guard let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue, let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                return
            }
            let rawAnimationCurve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).uintValue << 16
            let animationCurve = UIView.AnimationOptions(rawValue: rawAnimationCurve)

            bottomConstraint.constant = -keyboardFrame.size.height

            UIView.animate(withDuration: animationDuration, delay: 0.0, options: [.beginFromCurrentState, animationCurve], animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
}

extension UIViewController {
    func showParental(cancelable:Bool = false, onCompletion: ((UIAlertController.TextInputResult) -> Void)? = nil) {
        let cancelTitle = cancelable ? NSLocalizedString("Cancel", comment: "") : nil
        let alertController = UIAlertController(title: NSLocalizedString("Parental Permission", comment: ""), message: NSLocalizedString("Please enter your year of birth.", comment: ""), cancelButtonTitle: cancelTitle, okButtonTitle: NSLocalizedString("Confirm", comment: ""), validate: .predicate { text in
            var numberText = text
            // support arabic number
            let map = [
                "٠": "0",
                "١": "1",
                "٢": "2",
                "٣": "3",
                "٤": "4",
                "٥": "5",
                "٦": "6",
                "٧": "7",
                "٨": "8",
                "٩": "9"
            ]
            
            map.forEach { numberText = numberText.replacingOccurrences(of: $0, with: $1) }
            // valid age is from 18 to 117
            let currentYear = Date().year
            guard let input = Int(numberText), currentYear - input >= 18,  currentYear - input < 117 else {
                return false
            }
            
            return true
            }, textFieldConfiguration: { textField in
                textField.placeholder = NSLocalizedString("Year of birth", comment: "")
                textField.keyboardType = .numberPad
        }, textFieldshouldChange: { string in
            let numberPattern = "٠١٢٣٤٥٦٧٨٩0123456789"
            guard CharacterSet(charactersIn: numberPattern).isSuperset(of: CharacterSet(charactersIn: string)) else {
                return false
            }
            
            return true
        }
        ) { result in
            onCompletion?(result)
        }
        
        present(alertController, animated: true, completion: nil)
    }
}
