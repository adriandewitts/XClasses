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
}

//func pullViewModel(viewModel: ViewModelDelegate) -> ViewModelDelegate {
//    let flowController = FlowController.shared
//    var vm = viewModel
//
//    if String(describing: type(of: viewModel)) == "ViewModel" {
//        vm = flowController.viewModel
//    }
//
//    return vm
//}

// TODO: Change to below
//func pull() -> ViewModelDelegate
//{
//    return XUIFlowController.sharedInstance.viewModel
//}

class XUIViewController: UIViewController, ViewModelManagerDelegate {
    var viewModel: ViewModelDelegate!

    required init?(coder aDecoder: NSCoder) {
        viewModel = FlowController.viewModel
        super.init(coder: aDecoder)
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
