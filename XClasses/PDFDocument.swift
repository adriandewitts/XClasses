//
//  PDFDocument.swift
//  
//
//  Created by Adrian on 3/12/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit

protocol PDFPageDelegate {
    var _index: Int { get }
    var pdfDocument: PDFDocument { get }
}

class PDFDocument {
    let cachedImages = NSCache<NSNumber, UIImage>()
    var pdfDocument: CGPDFDocument?
    var firstRetry: Date?

    init(url: URL) {
        pdfDocument = CGPDFDocument(url as CFURL)
        cachedImages.countLimit = 5
    }

    // PDF is streamed
    func pdfPageImage(at index: Int, size: CGSize = UIScreen.main.bounds.size, error: @escaping (_ error: Error) -> Void = {_ in}, completion: @escaping (_ image: UIImage) -> Void = {_ in}) -> UIImage? {
        cachePages(index: index, size: size)

        if let image = cachedImages.object(forKey: NSNumber(value: index)) {
            completion(image)
            return image
        }

        if firstRetry == nil {
            firstRetry = Date()
        }

        if firstRetry!.timeIntervalSinceNow < TimeInterval(60.0) {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { timer in
                _ = self.pdfPageImage(at: index, size: size, completion: completion)
            })
        }
        else {
            // TODO: Send back timeout error
        }

        return nil
    }

    func cachePages(index: Int, size: CGSize = UIScreen.main.bounds.size) {
        cachePage(index: index, size: size)
        
        let queue = DispatchQueue(label: "caching")
        queue.async {
            self.cachePage(index: index + 1, size: size)
            self.cachePage(index: index - 1, size: size)
        }
    }

    func cachePage(index: Int, size: CGSize = UIScreen.main.bounds.size) {
        let n = NSNumber(value: index)
        guard index >= 0, index < pdfDocument!.numberOfPages, cachedImages.object(forKey: n) == nil else {
            return
        }

        if let image = pdfDocument?.imageFromPage(number: index + 1, with: size) {
            cachedImages.setObject(image, forKey: n)
        }
    }

    func resetCache() {
        cachedImages.removeAllObjects()
    }
}
