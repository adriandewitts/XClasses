//
//  DetailViewController.swift
//  
//
//  Created by Adrian on 13/10/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit

class PDFViewController: UIScrollImageViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()

        displayPage(size: view.bounds.size)

        if let text = viewModel.properties["text"]
        {
            imageView.isAccessibilityElement = true
            imageView.accessibilityTraits = UIAccessibilityTraitStaticText
            imageView.accessibilityLabel = text
        }
    }

    // For change in orientation (will recreate image from PDF)
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        displayPage(size: size)
        super.viewWillTransition(to: size, with: coordinator)
    }

    func displayPage(size: CGSize)
    {
        if let page = viewModel as? PDFPageDelegate
        {
            let image = page.pdfDocument.pdfPageImage(at: page._index, size: size, error: { error in
                // TODO: Show modal Timed out in own method
            }, completion: { image in
                self.imageView.image = image
            })
            if image == nil
            {
                runWaitAnimation()
            }
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        if let page = viewModel as? PDFPageDelegate
        {
            page.pdfDocument.resetCache()
        }

    }
}

