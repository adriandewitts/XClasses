//
//  UIScroll+ImageView.swift
//
//  Created by Adrian on 17/2/17.
//  Copyright © 2017 Adrian DeWitts. All rights reserved.
//

import UIKit
import Nuke

class UIScrollImageViewController: XUIViewController, UIScrollViewDelegate
{
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!
    var freshView = true
    var waitAnimationFileName: String? = "Wait"

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Load in image from viewModel

        if let imageURL = self.viewModel.properties["image"]
        {
            Nuke.loadImage(with: URL(string: imageURL)!, into: imageView)
        }

        if self.waitAnimationFileName != nil && self.imageView.image == nil
        {
            self.runWaitAnimation()
        }

        // Setup rest of ImageView with behaviours

        imageView.contentMode = UIViewContentMode.scaleAspectFit

        if UIScreen.main.traitCollection.userInterfaceIdiom == .phone
        {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(toggleNavigation))
        singleTap.numberOfTapsRequired = 1
        singleTap.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(singleTap)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(zoomView))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(doubleTap)

        singleTap.require(toFail: doubleTap)
    }

    func runWaitAnimation()
    {
        // TODO: work out proper default system - look at working out duration
        imageView.image = UIImage.animatedImageNamed(self.waitAnimationFileName!, duration: 3.0)
    }

    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        if freshView
        {
            scaleView(size: scrollView.bounds.size)
        }
    }

    func scaleView(size: CGSize)
    {
        scrollView.zoomScale = 1.0
        if let image = self.imageView.image
        {
            let proportionalSize = image.size.proportionalSizing(to: size, contentMode: scrollView.contentMode)
            imageView.frame = CGRect(origin: CGPoint.zero, size: proportionalSize)
        }

        let widthRatio = CGFloat(size.width / imageView.frame.size.width)
        let heightRatio = CGFloat(size.height / imageView.frame.size.height)
        var zoom: CGFloat = 0.0

        switch scrollView.contentMode
        {
        case .scaleAspectFit:
            zoom = min(widthRatio, heightRatio)
        case .scaleAspectFill:
            zoom = max(widthRatio, heightRatio)
        default:
            zoom = min(widthRatio, heightRatio)
        }

        scrollView.minimumZoomScale = min(widthRatio, heightRatio)
        scrollView.maximumZoomScale = zoom * 2
        scrollView.zoomScale = zoom

        freshView = false
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        scaleView(size: size)
        super.viewWillTransition(to: size, with: coordinator)
    }

    // Gestures

    func toggleNavigation(tapGesture: UITapGestureRecognizer)
    {
        navigationController?.setNavigationBarHidden(navigationController?.isNavigationBarHidden == false, animated: true)
    }

    func zoomView(tapGesture: UITapGestureRecognizer)
    {
        if (scrollView.zoomScale == scrollView.minimumZoomScale)
        {
            let center = tapGesture.location(in: scrollView)
            let size = imageView.frame.size
            let zoomRect = CGRect(x: center.x, y: center.y, width: (size.width / 2), height: (size.height / 2))
            scrollView.zoom(to: zoomRect, animated: true)
        }
        else
        {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }

    // Delegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView?
    {
        return self.imageView
    }

//    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
//    {
//
//    }
}
