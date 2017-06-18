//
//  UIPageViewController.swift
//  
//
//  Created by Adrian on 26/11/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit

class XUIPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, ViewModelManagerDelegate
{
    var viewModel = ViewModel() as ViewModelDelegate
    var viewModelCollection: [ViewModelDelegate] = []
    var pageControllerStoryBoardID = "ScrollImageViewID"

    override func viewDidLoad()
    {
        super.viewDidLoad()

        dataSource = self
        delegate = self

        viewModel = pullViewModel(viewModel: viewModel)
        viewModelCollection = viewModel.relatedCollection

        var index = 0
        if let indexAsString = viewModel.properties["index"]
        {
            index = Int(indexAsString)!
        }

        setViewControllers([self.controller(from: index)], direction: .forward, animated: true, completion: nil)
    }

    func controller(from index: Int) -> UIViewController
    {
        var controller = storyboard!.instantiateViewController(withIdentifier: pageControllerStoryBoardID) as! ViewModelManagerDelegate
        if var vm = viewModelCollection[safe: index]
        {
            vm._index = index
            controller.viewModel = vm
        }

        return controller as! UIViewController
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        let vm = (viewController as! ViewModelManagerDelegate).viewModel
        let index = vm._index + 1

        if index < viewModelCollection.count
        {
            return self.controller(from: index)
        }

        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        let vm = (viewController as! ViewModelManagerDelegate).viewModel
        let index = vm._index - 1

        if index >= 0
        {
            return self.controller(from: index)
        }

        return nil
    }
}
