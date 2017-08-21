//
//  CollectionViewController.swift
//  Bookbot
//
//  Created by Adrian on 17/8/17.
//  Copyright © 2017 Bookbot. All rights reserved.
//

import UIKit
import IGListKit
import Nuke

class CollectionViewController: UIViewController, ViewModelManagerDelegate {
    var viewModel = ViewModel() as ViewModelDelegate
    var viewModelCollection: [ViewModelDelegate] = []
    var reuseIdentifier = "Cell"

    @IBOutlet var collectionView: UICollectionView!
    class var workingRange: Int {
        return 3
    }
    lazy var adapter: ListAdapter = {
        return ListAdapter(updater: ListAdapterUpdater(), viewController: self, workingRangeSize: workingRange)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = pullViewModel(viewModel: viewModel)
        viewModelCollection = viewModel.relatedCollection

        adapter.collectionView = collectionView
        adapter.dataSource = self as ListAdapterDataSource
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        XUIFlowController.sharedInstance.viewModel = (sender as! CollectionViewCell).viewModel
    }
}

extension CollectionViewController: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        return viewModelCollection as! [ListDiffable]
    }

    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        return DefaultSectionController(viewModel: object as! ViewModel, standardSize: self.standardCellSize())
    }

    func emptyView(for listAdapter: ListAdapter) -> UIView? { return nil }

    // TODO: think this default out
    func standardCellSize() -> CGSize
    {
        let preferredCellWidth: CGFloat = 90.0
        let aspectRatio: CGFloat = 1.0
        let leftInset: CGFloat = 0.0
        let rightInset: CGFloat = 0.0
        let minimumCellSpacing: CGFloat = 0.0
        let screenWidth = screenSize().width - leftInset - rightInset
        let numberOfCells = floor(screenWidth / (preferredCellWidth + minimumCellSpacing))
        let cellWidth = (screenWidth / numberOfCells) - minimumCellSpacing

        return CGSize(width: cellWidth, height: cellWidth * aspectRatio)
    }
}

class DefaultSectionController: ListSectionController {
    var viewModel: ViewModelDelegate
    var standardSize = CGSize()

    init(viewModel: ViewModel, standardSize: CGSize) {
        self.viewModel = viewModel
        self.standardSize = standardSize
        super.init()
    }

    override func sizeForItem(at index: Int) -> CGSize {
        return standardSize
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        let cell = collectionContext!.dequeueReusableCellFromStoryboard(withIdentifier: "Cell", for: self, at: index) as! CollectionViewCell
        cell.assignViewModelToView(viewModel: viewModel)
        return cell
    }
}

class CollectionViewCell: UICollectionViewCell, ViewModelManagerDelegate
{
    var viewModel = ViewModel() as ViewModelDelegate
    @IBOutlet var imageView: XUIImageView!

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
