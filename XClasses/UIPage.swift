//
//  UIPageViewController.swift
//  
//
//  Created by Adrian on 26/11/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit

// TODO: Depracate and move to CollectionView

class XUIPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, ViewModelManagerDelegate
{
    var viewModel = ViewModel() as ViewModelDelegate
    var viewModelCollection: [ViewModelDelegate] = []
    var pageControllerStoryBoardID = "ScrollImageViewID"

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self

        viewModel = pullViewModel(viewModel: viewModel)
        viewModelCollection = viewModel.relatedCollection as! Array<ViewModelDelegate>

        if let firstViewModel = viewModelCollection.first {
            setViewControllers([controller(for: firstViewModel)], direction: .forward, animated: true, completion: nil)
        }
    }

    func controller(for viewModel: ViewModelDelegate) -> UIViewController {
        var controller = storyboard!.instantiateViewController(withIdentifier: pageControllerStoryBoardID) as! ViewModelManagerDelegate
        controller.viewModel = viewModel

        return controller as! UIViewController
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let vmc = self.viewModelCollection as! Array<ViewModel>
        let vc = viewController as! ViewModelManagerDelegate
        let vm = vc.viewModel as! ViewModel

        if var index = vmc.index(of: vm) {
            index += 1
            if index < viewModelCollection.count {
                return controller(for: viewModelCollection[index])
            }
        }

        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let vmc = self.viewModelCollection as! Array<ViewModel>
        let vc = viewController as! ViewModelManagerDelegate
        let vm = vc.viewModel as! ViewModel

        if var index = vmc.index(of: vm) {
            index -= 1
            if index >= 0 {
                return controller(for: viewModelCollection[index])
            }
        }

        return nil
    }
}
