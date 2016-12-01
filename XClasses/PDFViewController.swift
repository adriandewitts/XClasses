//
//  PDFController.swift
//  Beachcomber
//
//  Created by Adrian on 1/12/16.
//  Copyright © 2016 NACC. All rights reserved.
//

import UIKit

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
}

class PDFViewController: XUIPageViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()

        
    }
}