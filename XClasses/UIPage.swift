//
//  UIPageViewController.swift
//  Beachcomber
//
//  Created by Adrian on 26/11/16.
//  Copyright © 2016 NACC. All rights reserved.
//

import UIKit

class XUIPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, ViewModelManagerDelegate
{
    var viewModel = ViewModel() as ViewModelDelegate
    var viewModelCollection = [ViewModel() as ViewModelDelegate]
    var controllerCollection: [UIViewController] = []
    var pageControllerStoryBoardID = "ScrollImageViewID"

    override func viewDidLoad()
    {
        super.viewDidLoad()

        dataSource = self
        delegate = self

        viewModel = pullViewModel(viewModel: viewModel)
        viewModelCollection = viewModel.relatedCollection()

        for vm in viewModelCollection
        {
            var pc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: pageControllerStoryBoardID) as! ViewModelManagerDelegate
            pc.viewModel = vm
            controllerCollection.append(pc as! UIViewController)
        }

        let controller = [controllerCollection[0]]
        setViewControllers(controller, direction: .forward, animated: true, completion: nil)

        //self.view.backgroundColor = UIColor.yellow
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        let index = controllerCollection.index(of: viewController)! + 1

        if index < controllerCollection.count
        {
            return controllerCollection[index]
        }

        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        let index = controllerCollection.index(of: viewController)! - 1

        if index >= 0
        {
            return controllerCollection[index]
        }

        return nil
    }
}
