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
    var waitAnimationFileName: String? = "Wait"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load in image from viewModel

        if let imageURL = viewModel.properties["image"]
        {
            Nuke.loadImage(with: URL(string: imageURL)!, into: imageView)
            //TODO: When loaded reset zoom
        }

        if waitAnimationFileName != nil && imageView.image == nil
        {
            runWaitAnimation()
        }

        // Setup rest of ImageView with behaviours

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

        //resetZoom(at: scrollView.bounds.size)
    }

//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        resetZoom(at: scrollView.bounds.size)
//    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        resetZoom(at: size)
    }

    func resetZoom(at size: CGSize) {
        guard let image = imageView.image else {
            return
        }

        let aspect: Aspect = (scrollView.contentMode == .scaleAspectFill ? .fill : .fit)
        let (proportionalSize, _) = image.size.resizingAndScaling(to: size, with: aspect)
        imageView.frame = CGRect(origin: CGPoint.zero, size: proportionalSize)

        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 2.0
        scrollView.zoomScale = 1.0
    }

    func runWaitAnimation()
    {
        // TODO: work out proper default system - look at working out duration
        imageView.image = UIImage.animatedImageNamed(waitAnimationFileName!, duration: 3.0)
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
