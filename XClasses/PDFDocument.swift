//
//  PDFDocument.swift
//  
//
//  Created by Adrian on 3/12/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit
import Hydra

protocol PDFPageDelegate {
    var pageNumber: Int { get }
    var pdfDocument: PDFDocument { get }
}

enum PDFError: LocalizedError {
    case pageNotReady

    public var errorDescription: String? {
        switch self {
        case .pageNotReady:
            return NSLocalizedString("Page is still downloading.", comment: "")
        }
    }
}

class PDFDocument {
    let cachedImages = NSCache<NSNumber, UIImage>()
    let cacheImageCount = 5
    var pdfDocument: CGPDFDocument?
    var firstRetry: Date?

    init(url: URL) {
        pdfDocument = CGPDFDocument(url as CFURL)
        cachedImages.countLimit = cacheImageCount
    }

    init() {
        cachedImages.countLimit = cacheImageCount
    }

    func pdfPageImage(pageNumber: Int, size: CGSize = UIScreen.main.bounds.size) -> Promise<UIImage> {
        return Promise<UIImage>(in: .main) { resolve, reject, _ in
            self.cachePages(pageNumber: pageNumber, size: size)
            if let image = self.cachedImages.object(forKey: NSNumber(value: pageNumber)) {
                resolve(image)
            }
            else {
                reject(PDFError.pageNotReady)
            }
        }
    }

    func cachePages(pageNumber: Int, size: CGSize = UIScreen.main.bounds.size) {
        cachePage(pageNumber: pageNumber, size: size)
        
        let queue = DispatchQueue(label: "caching")
        queue.async {
            self.cachePage(pageNumber: pageNumber + 1, size: size)
            self.cachePage(pageNumber: pageNumber - 1, size: size)
        }
    }

    func cachePage(pageNumber: Int, size: CGSize = UIScreen.main.bounds.size) {
        let n = NSNumber(value: pageNumber)
        let cachedImage = cachedImages.object(forKey: n)
        // TODO: if Sizes are different then recache
        guard pageNumber >= 1, pdfDocument != nil, pageNumber <= pdfDocument!.numberOfPages, cachedImage == nil else {
            return
        }

        if let image = pdfDocument?.imageFromPage(number: pageNumber, with: size) {
            cachedImages.setObject(image, forKey: n)
        }
    }

    func resetCache() {
        cachedImages.removeAllObjects()
    }
}
