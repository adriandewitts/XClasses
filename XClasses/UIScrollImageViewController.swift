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

    override func viewDidLoad()
    {
        super.viewDidLoad()

        //scrollView.delegate = self
        //scrollView.scrollsToTop = false
        //scrollView.bounces = false
        //scrollView.showsHorizontalScrollIndicator = false
        //scrollView.showsVerticalScrollIndicator = false
        //scrollView.isUserInteractionEnabled = true
        //scrollView.bouncesZoom = false
        //scrollView.maximumZoomScale = 2.0
        //scrollView.minimumZoomScale = 1.0

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
            imageView.sizeToFit()
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

        let width = CGFloat(self.view.bounds.size.width / imageView.frame.size.width)
        let height = CGFloat(self.view.bounds.size.height / imageView.frame.size.height)
        let zoom: CGFloat = min(width, height)

        scrollView.minimumZoomScale = zoom
        scrollView.maximumZoomScale = zoom * 3
        scrollView.zoomScale = zoom
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
        return scrollView.subviews[0]
    }
}
