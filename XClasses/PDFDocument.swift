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

    func cachePages(index: Int, rect: CGRect)
    {
        // Fan out the caching from the page to be cached
        cachePage(index: index, rect: rect)
        cachePage(index: index + 1, rect: rect)
        cachePage(index: index - 1, rect: rect)
        cachePage(index: index + 2, rect: rect)
        cachePage(index: index - 2, rect: rect)
    }

    func cachePage(index: Int, rect: CGRect)
    {
        // put in threading here
        if index >= 0 || index < pdfDocument!.numberOfPages
        {
            let n = NSNumber(value: index)
            if cachedImages.object(forKey: n) == nil
            {
                if let uiImage = pdfDocument!.uiImageFromPDFPage(pageNumber: index + 1, rect: rect)
                {
                    cachedImages.setObject(uiImage, forKey: n)
                }
            }
        }
    }

    func pdfPageImage(at index: Int) -> UIImage?
    {
        return self.cachedImages.object(forKey: NSNumber(value: index))
    }
}
