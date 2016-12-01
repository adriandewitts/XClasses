//
//  UIPageViewController.swift
//  Beachcomber
//
//  Created by Adrian on 26/11/16.
//  Copyright © 2016 NACC. All rights reserved.
//

import UIKit

class XUIPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, ViewModelDelegate
{
    var viewModel = ViewModel()
    var viewModelCollection = [ViewModel()]
    var controllerCollection: [UIViewController] = []
    var currentPageControllerIndex = 0

    override func viewDidLoad()
    {
        super.viewDidLoad()

        dataSource = self
        delegate = self

        viewModel = pullViewModel(viewModel: viewModel)
        viewModelCollection = viewModel.relatedCollection()

        for vm in viewModelCollection
        {
            var pc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: XUIFlowController.sharedInstance.pageControllerStoryBoardID) as! ViewModelDelegate
            pc.viewModel = vm
            controllerCollection.append(pc as! UIViewController)
        }

        let controller = [controllerCollection[0]]
        setViewControllers(controller, direction: .forward, animated: true, completion: nil)

        hideNavigationBar()
    }

    func hideNavigationBar()
    {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        if (currentPageControllerIndex + 1) < controllerCollection.count
        {
            currentPageControllerIndex += 1
            let controller = controllerCollection[currentPageControllerIndex]
            return controller
        }

        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        if (currentPageControllerIndex - 1) > 0
        {
            currentPageControllerIndex -= 1
            let controller = controllerCollection[currentPageControllerIndex]
            return controller
        }

        return nil
    }
}
