//
//  DetailViewController.swift
//  
//
//  Created by Adrian on 13/10/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit
import Hydra

class PDFViewController: UIScrollImageViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        displayPage(size: view.bounds.size)

        if let text = viewModel.viewProperty(forKey:"text") {
            imageView.isAccessibilityElement = true
            imageView.accessibilityTraits = UIAccessibilityTraits.staticText
            imageView.accessibilityLabel = text as? String
        }
    }

    // For change in orientation (will recreate image from PDF)
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        displayPage(size: size)
        super.viewWillTransition(to: size, with: coordinator)
    }

    func displayPage(size: CGSize) {
        if let page = viewModel as? PDFPageDelegate {
            page.pdfDocument.pdfPageImage(pageNumber: page.pageNumber, size: size).retry(30) {_,_ in
                // Wait for a second to try again
                sleep(1)
                return true
            }.then(in: .main) { image in
                self.imageView.image = image
                self.resetZoom(at: size)
                self.hideEmptyView()
            }.catch { error in
                self.presentErrorAlert(error: error)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        if let page = viewModel as? PDFPageDelegate {
            page.pdfDocument.resetCache()
        }
    }
}

