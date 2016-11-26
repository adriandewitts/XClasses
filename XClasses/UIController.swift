//
//  Extension.swift
//  Sprite
//
//  Created by Adrian on 5/09/2016.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit

// Mark: Handy Functions

func screenSize() -> CGSize
{
    return UIScreen.main.bounds.size
}

// Mark: View & Flow Controllers

protocol ViewModelDelegate
{
    var viewModel: ViewModel { get set }
}

class XUIFlowController: ViewModelDelegate
{
    static let sharedInstance = XUIFlowController()
    var viewModel = ViewModel()
    var pageControllerStoryBoardID = ""
}

func pullViewModel(viewModel: ViewModel) -> ViewModel
{
    let flowController = XUIFlowController.sharedInstance
    var vm = viewModel

    if String(describing: type(of: viewModel)) == "ViewModel"
    {
        vm = flowController.viewModel
    }

    return vm
}

class XUIViewController: UIViewController, ViewModelDelegate
{
    var viewModel = ViewModel()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        viewModel = pullViewModel(viewModel: viewModel)
    }
}

class XSplitViewController: UISplitViewController, UISplitViewControllerDelegate
{
    override func viewDidLoad()
    {
        super.viewDidLoad()

//        let navigationController = self.viewControllers[self.viewControllers.count - 1] as! UINavigationController
//        navigationController.topViewController!.navigationItem.leftBarButtonItem = self.displayModeButtonItem
        self.delegate = self
    }

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool
    {
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


