//
//  UIScroll+ImageView.swift
//  Beachcomber
//
//  Created by Adrian on 17/2/17.
//  Copyright © 2017 NACC. All rights reserved.
//

import UIKit
import Nuke

class UIScrollImageViewController: XUIViewController, UIScrollViewDelegate
{
    var image: UIImage?

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!
    var freshView = true

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(toggleNavigation))
        singleTap.numberOfTapsRequired = 1
        singleTap.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(singleTap)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(zoomView))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(doubleTap)

        singleTap.require(toFail: doubleTap)

        imageView.contentMode = UIViewContentMode.scaleAspectFit

        // Use image object variable, or image in viewmodel
        if image != nil
        {
            imageView.image = image
        }
        else
        {
            let properties = viewModel.properties()
            if let imagePath = properties["image"]
            {
                Nuke.loadImage(with: URL(string: imagePath)!, into: imageView)
                image = imageView.image
            }
        }

        if UIScreen.main.traitCollection.userInterfaceIdiom == .phone
        {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }

    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        if freshView
        {
            fitView(size: scrollView.bounds.size)
        }
    }

    func fitView(size: CGSize)
    {
        if let image = image
        {
            imageView.frame.size = image.size.proportionalSizing(to: size, contentMode: scrollView.contentMode)
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
        case .top:
            zoom = widthRatio
        default:
            zoom = min(widthRatio, heightRatio)
        }

        scrollView.minimumZoomScale = zoom
        scrollView.maximumZoomScale = zoom * 2
        scrollView.zoomScale = zoom

        freshView = false
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        fitView(size: size)
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
        return imageView
    }
}
