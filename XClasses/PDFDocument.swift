//
//  PDFDocument.swift
//  
//
//  Created by Adrian on 3/12/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit

//protocol PDFDocumentDelegate
//{
////    func pdfDocument() -> PDFDocument
////    func startIndex() -> Int
//
//    var pdfDocument: PDFDocument? { get }
//    var startIndex: Int { get }
//}

protocol PDFPageDelegate
{
    var _index: Int { get }
    var pdfDocument: PDFDocument { get }
}

class PDFDocument
{
    let cachedImages = NSCache<NSNumber, UIImage>()
    var pdfDocument: CGPDFDocument?
    var firstRetry: Date?

    init(url: URL)
    {
        pdfDocument = CGPDFDocument(url as CFURL)
        cachedImages.countLimit = 5
    }

    // PDF is fully loaded
//    func pdfPageImage(at index: Int, size: CGSize = UIScreen.main.bounds.size) -> UIImage?
//    {
//        cachePages(index: index, size: size)
//        return cachedImages.object(forKey: NSNumber(value: index))
//    }

    // PDF is streamed
    func pdfPageImage(at index: Int, size: CGSize = UIScreen.main.bounds.size, error: @escaping (_ error: Error) -> Void = {_ in}, completion: @escaping (_ image: UIImage) -> Void = {_ in}) -> UIImage?
    {
        cachePages(index: index, size: size)

        if let image = cachedImages.object(forKey: NSNumber(value: index))
        {
            completion(image)
            return image
        }

        if firstRetry == nil
        {
            firstRetry = Date()
        }
        if firstRetry!.timeIntervalSinceNow < TimeInterval(60.0)
        {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { timer in
                _ = self.pdfPageImage(at: index, size: size, completion: completion)
            })
        }
        else
        {
            // TODO: Send back timeout error
        }

        return nil
    }

    func cachePages(index: Int, size: CGSize = UIScreen.main.bounds.size)
    {
        cachePage(index: index, size: size)
        
        let queue = DispatchQueue(label: "pdfer")

        queue.async
        {
            self.cachePage(index: index + 1, size: size)
            self.cachePage(index: index - 1, size: size)
        }
    }

    func cachePage(index: Int, size: CGSize = UIScreen.main.bounds.size)
    {
        if index >= 0 || index < pdfDocument!.numberOfPages
        {
            let n = NSNumber(value: index)
            if cachedImages.object(forKey: n) == nil
            {
                // Gets the longest length of the size and use that for the width of the PDF
                let maxLength = max(size.width, size.height)
                let minLength = min(size.width, size.height)
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


}
