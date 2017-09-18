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

    // TODO: Better wait defaults
    var waitAnimationFileName = "wait"
    var waitAnimationDuration = 2.0
    var waitView: UIImageView?
    var waitViewRect: CGRect {
        return CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load in image from viewModel

        if let imageURL = viewModel.properties["image"]
        {
            Nuke.loadImage(with: URL(string: imageURL)!, into: imageView)
            //TODO: When loaded reset zoom
        }

        waitAnimation()

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

    /// Setup wait animation centred in scrollview. Will wait 0.25 seconds to run and checks if image has already loaded.
    func waitAnimation()
    {
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { timer in
            //TODO: Fix this - window is not set
            if self.imageView.image == nil, self.waitView == nil, let applicationDelegate = UIApplication.shared.delegate as! AppDelegate?, let window = applicationDelegate.window {
                self.waitView = UIImageView(frame: self.waitViewRect)
                self.waitView?.center = window.convert(window.center, from: window)
                self.scrollView.addSubview(self.waitView!)
            }

            self.waitView?.image = UIImage.animatedImageNamed(self.waitAnimationFileName, duration: self.waitAnimationDuration)
        }
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
