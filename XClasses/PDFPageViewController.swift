//
//  DetailViewController.swift
//  Beachcomber
//
//  Created by Adrian on 13/10/16.
//  Copyright © 2016 NACC. All rights reserved.
//

import UIKit

class PDFPageViewController: UIScrollImageViewController
{
    override func viewDidLoad()
    {
        if let page = viewModel as? PDFPageDelegate
        {
            self.image = page.pdfDocument().pdfPageImage(at: page.index(), size: self.view.bounds.size)
            makeAccessible()
        }

        super.viewDidLoad()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        if let page = viewModel as? PDFPageDelegate
        {
            self.image = page.pdfDocument().pdfPageImage(at: page.index(), size: size)
            makeAccessible()
        }

        super.viewWillTransition(to: size, with: coordinator)
    }

    func makeAccessible()
    {
        self.imageView.isAccessibilityElement = true
        self.imageView.accessibilityTraits = UIAccessibilityTraitStaticText
        self.imageView.accessibilityLabel = viewModel.properties()["text"]
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        print("memory warning")
        if let page = viewModel as? PDFPageDelegate
        {
            page.pdfDocument().resetCache()
        }

    }

}

