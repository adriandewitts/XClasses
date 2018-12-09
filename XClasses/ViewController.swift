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
