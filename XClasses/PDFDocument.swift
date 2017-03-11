//
//  PDFDocument.swift
//  Beachcomber
//
//  Created by Adrian on 3/12/16.
//  Copyright © 2016 NACC. All rights reserved.
//

import UIKit

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

class PDFDocument
{
    let cachedImages = NSCache<NSNumber, UIImage>()
    let pdfDocument: CGPDFDocument?

    init(path: String)
    {
        pdfDocument = CGPDFDocument(path.toURL() as CFURL)
        cachedImages.countLimit = 5
    }

    func cachePages(index: Int)
    {
        cachePage(index: index)
        
        let queue = DispatchQueue(label: "pdfer")

        queue.async
        {
            self.cachePage(index: index + 1)
            self.cachePage(index: index - 1)
        }
    }

    func cachePage(index: Int)
    {
        if index >= 0 || index < pdfDocument!.numberOfPages
        {
            let n = NSNumber(value: index)
            if cachedImages.object(forKey: n) == nil
            {
                // Gets the longest length of the screen and uses that for the width of the PDF
                let screenSize = UIScreen.main.bounds
                let maxLength = max(screenSize.width, screenSize.height)
                let minLength = min(screenSize.width, screenSize.height)
                let size = CGSize(width: maxLength, height: minLength)

                if let uiImage = pdfDocument!.uiImageFromPDFPage(pageNumber: index + 1, size: size)
                {
                    cachedImages.setObject(uiImage, forKey: n)
                    print("cache: \(index)")
                }
            }
        }
    }

    func resetCache()
    {
        cachedImages.removeAllObjects()
    }

    func pdfPageImage(at index: Int, size: CGSize) -> UIImage?
    {
        cachePages(index: index)
        return self.cachedImages.object(forKey: NSNumber(value: index))
    }
}
