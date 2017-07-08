//
//  DetailViewController.swift
//  
//
//  Created by Adrian on 13/10/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit
import Hydra

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
            page.pdfDocument.pdfPageImage(at: page._index, size: size).retry(20).then(in: .main) { image in
                self.imageView.image = image
                self.resetZoom(at: size)
            }.catch { error in
                // Warn problems with internet connection
            }

            if self.imageView.image == nil
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

