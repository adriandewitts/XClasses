//
//  PDFController.swift
//  Beachcomber
//
//  Created by Adrian on 1/12/16.
//  Copyright © 2016 NACC. All rights reserved.
//

import UIKit
import AssistantKit

// This stuff is to be in a PDF controller over document controller
// PDF - document file name, image cache
// set PDF & page number on view
// Cache from page, how many cached (cache whole chapter)
// get from cache (then remove)

// PageView
// View did load
// On set PDF - draw image
// Setup other items
// Setup tiledview for zoom

protocol PDFDocumentDelegate
{
    func pdfDocument() -> PDFDocument
    func startIndex() -> Int
}

protocol PDFPageDelegate
{
    func pdfDocument() -> PDFDocument
    func index() -> Int
}

class PDFDocumentViewController: XUIPageViewController
{
    override func viewDidLoad()
    {
        viewModel = pullViewModel(viewModel: viewModel)
        cachePage(offset: 0)

        // Super needs to go at end so we can cache images before this is called
        super.viewDidLoad()
    }

    override func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        let controller = super.pageViewController(pageViewController, viewControllerAfter: viewController)
        cachePage(offset: controllerCollection.index(of: viewController)! + 1)

        return controller
    }

    override func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        let controller = super.pageViewController(pageViewController, viewControllerBefore: viewController)
        cachePage(offset: controllerCollection.index(of: viewController)! - 1)

        return controller
    }

    func cachePage(offset: Int)
    {
        if let delegate = viewModel as? PDFDocumentDelegate
        {
            let pdfDocument = delegate.pdfDocument()
            let index = delegate.startIndex() + offset
            pdfDocument.cachePage(index: index)
        }
    }
}
