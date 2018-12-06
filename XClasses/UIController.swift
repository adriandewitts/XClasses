//
//  Extension.swift
//  Sprite
//
//  Created by Adrian on 5/09/2016.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit

// Mark: Handy Functions

func screenSize() -> CGSize {
    return UIScreen.main.bounds.size
}

// Mark: View & Flow Controllers

protocol ViewModelManagerDelegate {
    var viewModel: ViewModelDelegate! { get set }
}

/// The first ViewModel has to be set before the ViewModel is accessed
class FlowController: ViewModelManagerDelegate {
    static let shared = FlowController()
    var viewModel: ViewModelDelegate!
    var transitionImage: UIImage?

    class var viewModel: ViewModelDelegate {
        get {
            return FlowController.shared.viewModel
        }
        set(viewModel) {
            FlowController.shared.viewModel = viewModel
        }
    }
    
    class var hasViewModel: Bool {
        if FlowController.shared.viewModel != nil {
            return true
        }
        return false
    }
}

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

extension UIStoryboard {
    class func controller(_ identifier: String, storyboard: String = "Main") -> UIViewController {
        return UIStoryboard(name: storyboard, bundle: nil).instantiateViewController(withIdentifier: identifier)
    }
}

class XSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()

//        let navigationController = viewControllers[viewControllers.count - 1] as! UINavigationController
//        navigationController.topViewController!.navigationItem.leftBarButtonItem = displayModeButtonItem
        delegate = self
    }

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
//        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
//        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
//        if topAsDetailController.detailItem == nil
//        {
//            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
//            return true
//        }
        return true
    }
}

extension UISplitViewController {
    func toggleMasterView() {
        let button = displayModeButtonItem
        let _ = button.target?.perform(button.action, with: button)
    }
}
