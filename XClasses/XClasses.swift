//
//  Extension.swift
//  Sprite
//
//  Created by Adrian on 5/09/2016.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit
import Nuke

protocol XViewController
{
    var viewModel: XViewModel { get set }
}

class XUIFlowController: XViewController
{
    static let sharedInstance = XUIFlowController()
    var viewModel = XViewModel()
}

class XUIViewController: UIViewController
{
    let flowController = XUIFlowController.sharedInstance
    var viewModel = XViewModel()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        viewModel = self.flowController.viewModel
    }
}

class XUIPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate
{
    let flowController = XUIFlowController.sharedInstance
    var viewModel = XViewModel()
    
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

class XUICollectionViewController: UICollectionViewController, XViewController
{
    let flowController = XUIFlowController.sharedInstance
    var viewModel = XViewModel()
    var viewModelCollection = [XViewModel()]
    var numberOfSections = 1
    var numberOfItems = 1
    var reuseIdentifier = "XCell"
    var cellWidthSize: CGFloat = 90.0
    var aspectRatio: CGFloat = 1.0
    var contentMode = UIViewContentMode.scaleAspectFit
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
        viewModel = self.flowController.viewModel
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return numberOfSections
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return numberOfItems
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! XUICollectionViewCell
        cell.assignViewModelToView(viewModel: viewModelCollection[(indexPath as NSIndexPath).item])
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewFlowLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize
    {
        return standardisedCellSize(cellWidthSize, aspectRatio: aspectRatio, leftInset: collectionViewLayout.sectionInset.left, rightInset: collectionViewLayout.sectionInset.right, minimumCellSpacing: collectionViewLayout.minimumInteritemSpacing)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        self.flowController.viewModel = (sender as! XUICollectionViewCell).viewModel
    }
    
//    @IBAction func passViewModel(_ sender: XUIButton)
//    {
//        self.flowController.viewModel = sender.viewModel
//    }
}

func screenSize() -> CGSize
{
    return UIScreen.main.bounds.size
}

func standardisedCellSize(_ preferredCellWidth: CGFloat = 90.0, aspectRatio: CGFloat = 1.0, leftInset: CGFloat = 0.0, rightInset: CGFloat = 0.0, minimumCellSpacing: CGFloat = 0.0) -> CGSize
{
    let screenWidth = screenSize().width - leftInset - rightInset
    let numberOfCells = floor(screenWidth / (preferredCellWidth + minimumCellSpacing))
    let cellWidth = (screenWidth / numberOfCells) - minimumCellSpacing
    
    return CGSize(width: cellWidth, height: cellWidth * aspectRatio)
}

class XUIButton: UIButton
{
    var viewModel = XViewModel()
}

class XUIImageView: UIImageView
{
    var viewModel = XViewModel()
}

class XUICollectionViewCell: UICollectionViewCell
{
    var viewModel = XViewModel()
    @IBOutlet weak var image: XUIImageView!
    
    func assignViewModelToView(viewModel: XViewModel)
    {
        self.viewModel = viewModel
        let properties = viewModel.properties()
        if let imagePath = properties["image"]
        {
            image.contentMode = UIViewContentMode.scaleAspectFit
            // Extend URL so it can figure its shit out - local or web
            let url = URL(fileURLWithPath: imagePath)
            Nuke.loadImage(with: url, into: image)
        }
    }
}

