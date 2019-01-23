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
import RealmSwift

//TODO: Autolayout for cells. At the moment we calculate the size

/// CollectionView Controller hold ViewModel and its viewModelCollection and configures best practices for UIViewController. It implements IGListKit. This is currently in flux.
class CollectionViewController: UIViewController, ListAdapterDataSource, ViewModelManagerDelegate /*, ListWorkingRangeDelegate */ {
    @IBOutlet var emptyView: UIView?
    @IBOutlet var collectionView: UICollectionView!
    var viewModel: ViewModelDelegate!
    var viewModelCollection: Array<ViewModelDelegate> = []
    //var notificationToken: NotificationToken? = nil
    var workingRange: Int { return 20 }
    lazy var adapter: ListAdapter = {
        return ListAdapter(updater: ListAdapterUpdater(), viewController: self, workingRangeSize: workingRange)
    }()
    
    // TODO: By default set 3 squares for iphone for the width, more for iPad
    lazy var calculatedCellSize: CGSize = {
//        var resizer: CGFloat = 0.0
//        let spacing = cellInset.left + cellInset.right
//        let cellAndSpacingWidth = preferredCellSize.width + spacing
//        let numberOfCells = floor(collectionViewSize.width / cellAndSpacingWidth)
//        let widthSansSpacing = collectionViewSize.width - (spacing * numberOfCells)
//        let widthCells = preferredCellSize.width * numberOfCells
//        resizer = widthSansSpacing / widthCells
//        cellSize.width = preferredCellSize.width * resizer
//        cellSize.height = preferredCellSize.height * resizer
//        return cellSize.height
        return CGSize(width: 250.0, height: 250.0)
    }()
    
    var cellSize: CGSize { return calculatedCellSize }

    override func viewDidLoad() {
        super.viewDidLoad()

        UICollectionView.appearance().isPrefetchingEnabled = false

        viewModel = FlowController.viewModel

        adapter.collectionView = collectionView
        adapter.dataSource = self as ListAdapterDataSource

        loadViewModelCollection()
    }

    func loadViewModelCollection() {
        viewModelCollection = viewModel.relatedCollection
        self.adapter.performUpdates(animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Transition ViewModel to next screen
        let cell = sender as! CollectionViewCell
        FlowController.viewModel = cell.viewModel
        
        // Transition the representative image to the next screen
//        if let transitionImage = cell.imageView.image {
//            FlowController.shared.transitionImage = transitionImage
//        }
    }

    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        return viewModelCollection as! [ListDiffable]
    }

    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        return SectionController(viewModel: object as! ViewModel)
    }

    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return emptyView
    }

//    func listAdapter(_ listAdapter: ListAdapter, sectionControllerWillEnterWorkingRange sectionController: ListSectionController) {
//        if let sectionController = sectionController as? SectionController {
//            let viewModel = sectionController.viewModel
//            if let imagePath = viewModel.properties["image"], let imageURL = URL(string: imagePath) {
//                let preheater = ImagePreheater()
//                let requests = [ImageRequest(url: imageURL)]
//                preheater.startPreheating(with: requests)
//            }
//        }
//    }

//    func listAdapter(_ listAdapter: ListAdapter, sectionControllerDidExitWorkingRange sectionController: ListSectionController) {
//        // Nothing to do
//    }
}

class SectionController: ListSectionController {
    var viewModel: ViewModelDelegate
    var cellInset: UIEdgeInsets { return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0) }
    var reuseIdentifier: String { return "Cell" }
    
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init()
        self.inset = cellInset
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        return (viewController as! CollectionViewController).cellSize
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        let cell = collectionContext!.dequeueReusableCellFromStoryboard(withIdentifier: reuseIdentifier, for: self, at: index) as! CollectionViewCell
        cell.assign(viewModel: viewModel)
        return cell
    }
}

class CollectionViewCell: UICollectionViewCell, ViewModelManagerDelegate {
    var viewModel: ViewModelDelegate!
    var viewMap: [String: UIView] = [:]
    //@IBOutlet var imageView: ImageView!
    //@IBOutlet weak var label: UILabel!
    

    func assign(viewModel: ViewModelDelegate) {
        self.viewModel = viewModel
        viewMap = contentView.map(viewModel: viewModel)
        
//        if let imagePath = viewModel["image"], let imageURL = URL(string: imagePath as! String) {
//            imageView.contentMode = UIView.ContentMode.scaleAspectFit
//            Nuke.loadImage(with: imageURL, options: ImageLoadingOptions(placeholder: UIImage(named: "Placeholder"), transition: .fadeIn(duration: 0.15)), into: imageView)
//        }
    }
}
