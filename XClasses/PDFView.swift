//
//  PDFView.swift
//  Beachcomber
//
//  Created by Adrian on 3/12/16.
//  Copyright © 2016 NACC. All rights reserved.
//

import UIKit

class PDFPageView: UIScrollView
{
    
}

class PDFPageSubview: UIView
{
    var pdfDocument: PDFDocument
    var pageNumber = 0
    var aspectFill = true

    init(pdfDocument: PDFDocument, pageNumber: Int, rect: CGRect, aspectFill: Bool = true)
    {
        self.pdfDocument = pdfDocument
        self.pageNumber = pageNumber
        self.aspectFill = aspectFill

        super.init(frame: rect)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override class var layerClass: AnyClass
    {
        return CATiledLayer.self
    }

    override func draw(_ layer: CALayer, in ctx: CGContext)
    {
        guard let page = pdfDocument.pdfDocument?.page(at: pageNumber) else { return }
        let rect = self.superview!.frame

        // Determine the size of the PDF page.
        let pageRect = page.getBoxRect(.mediaBox)
        let widthRatio = Double(rect.size.width) / Double(pageRect.size.width)
        let heightRatio = Double(rect.size.height) / Double(pageRect.size.height)
        var scale: CGFloat = 1.0

        if aspectFill
        {
            scale = CGFloat(min(widthRatio, heightRatio))
        }
        else
        {
            scale = CGFloat(max(widthRatio, heightRatio))
        }

        //scale *= 2.0

        let newRect = CGRect(x: 0.0, y: 0.0, width: scale * pageRect.size.width, height: scale * pageRect.size.height)

        UIGraphicsBeginImageContextWithOptions(newRect.size, true, 1)
        let context = ctx

        // First fill the background with white.
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context.fill(newRect)

        context.saveGState()
        // Flip the context so that the PDF page is rendered right side up.
        context.translateBy(x: 0, y: newRect.size.height)
        context.scaleBy(x: 1, y: -1)

        // Scale the context so that the PDF page is rendered at the correct size for the zoom level.
        context.scaleBy(x: scale, y: scale)

        context.interpolationQuality = .high
        context.setRenderingIntent(.defaultIntent)

        context.drawPDFPage(page)
        context.restoreGState()
    }
}
