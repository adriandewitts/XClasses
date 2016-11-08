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

protocol XViewModelController
{
    var viewModel: ViewModel { get set }
}

class XUIFlowController: XViewModelController
{
    static let sharedInstance = XUIFlowController()
    var viewModel = ViewModel()
}

class XUIViewController: UIViewController
{
    let flowController = XUIFlowController.sharedInstance
    var viewModel = ViewModel()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        viewModel = self.flowController.viewModel
    }
}

class XUIPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate
{
    let flowController = XUIFlowController.sharedInstance
    var viewModel = ViewModel()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        viewModel = self.flowController.viewModel
        dataSource = self
        delegate = self
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        return nil
    }
}


