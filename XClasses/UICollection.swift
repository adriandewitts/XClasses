//
//  UICollection.swift
//  XClasses
//
//  Created by Adrian on 13/10/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit
import Nuke

class XUICollectionViewController: UICollectionViewController, ViewModelManagerDelegate
{
    var viewModel = ViewModel() as ViewModelDelegate
    var viewModelCollection = [ViewModel() as ViewModelDelegate]
    var numberOfSections = 1
    var numberOfItems = 1
    var reuseIdentifier = "Cell"
    var cellWidthSize: CGFloat = 90.0
    var aspectRatio: CGFloat = 1.0
    var contentMode = UIViewContentMode.scaleAspectFit

    override func viewDidLoad()
    {
        super.viewDidLoad()

        viewModel = pullViewModel(viewModel: viewModel)
        viewModelCollection = viewModel.relatedCollection

        self.clearsSelectionOnViewWillAppear = false
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
        return viewModelCollection.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! XUICollectionViewCell
        cell.assignViewModelToView(viewModel: viewModelCollection[(indexPath as NSIndexPath).item])

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewFlowLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize
    {
        return self.standardisedCellSize(cellWidthSize, aspectRatio: aspectRatio, leftInset: collectionViewLayout.sectionInset.left, rightInset: collectionViewLayout.sectionInset.right, minimumCellSpacing: collectionViewLayout.minimumInteritemSpacing)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        XUIFlowController.sharedInstance.viewModel = (sender as! XUICollectionViewCell).viewModel
    }

    func standardisedCellSize(_ preferredCellWidth: CGFloat = 90.0, aspectRatio: CGFloat = 1.0, leftInset: CGFloat = 0.0, rightInset: CGFloat = 0.0, minimumCellSpacing: CGFloat = 0.0) -> CGSize
    {
        let screenWidth = screenSize().width - leftInset - rightInset
        let numberOfCells = floor(screenWidth / (preferredCellWidth + minimumCellSpacing))
        let cellWidth = (screenWidth / numberOfCells) - minimumCellSpacing

        return CGSize(width: cellWidth, height: cellWidth * aspectRatio)
    }
}

class XUICollectionViewCell: UICollectionViewCell, ViewModelManagerDelegate
{
    var viewModel = ViewModel() as ViewModelDelegate
    @IBOutlet weak var imageView: XUIImageView!

    func assignViewModelToView(viewModel: ViewModelDelegate)
    {
        self.viewModel = viewModel
        let properties = viewModel.properties
        if let imagePath = properties["image"]
        {
            imageView.contentMode = UIViewContentMode.scaleAspectFit
            Nuke.loadImage(with: URL(string: imagePath)!, into: imageView)
        }
    }
}
