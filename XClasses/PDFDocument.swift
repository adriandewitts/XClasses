//
//  PDFDocument.swift
//  Beachcomber
//
//  Created by Adrian on 3/12/16.
//  Copyright © 2016 NACC. All rights reserved.
//

import UIKit

class PDFDocument
{
    let cachedImages = NSCache<NSNumber, UIImage>()
    let pdfDocument: CGPDFDocument?

    init(path: String)
    {
        pdfDocument = CGPDFDocument(path.toURL() as CFURL)
    }

    func cacheImages(pageRange: (Int, Int), rect: CGRect)
    {
        let (startPageNumber, endPageNumber) = pageRange
        // Do page caching as specified by the delegate
        for pageNumber in startPageNumber...endPageNumber
        {
            // put in threading here
            let n = NSNumber(value: pageNumber)
            if cachedImages.object(forKey: n) == nil
            {
                if let uiImage = pdfDocument!.uiImageFromPDFPage(pageNumber: pageNumber, rect: rect)
                {
                    cachedImages.setObject(uiImage, forKey: n)
                }

            }
        }
    }

    func pdfPageImage(at pageNumber: Int) -> UIImage?
    {
        return self.cachedImages.object(forKey: NSNumber(value: pageNumber))
    }
}
