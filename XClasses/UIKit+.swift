//
//  UIImage+.swift
//  Beachcomber
//
//  Created by Adrian on 1/12/16.
//  Copyright © 2016 NACC. All rights reserved.
//

import UIKit

extension CGPDFDocument
{
    func uiImageFromPDFPage(pageNumber: Int, rect: CGRect, aspectFill: Bool = true) -> UIImage?
    {
        guard let page = self.page(at: pageNumber) else { return nil }

        // Determine the size of the PDF page.
        var pageRect = page.getBoxRect(.mediaBox)
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

        scale *= 2.0

        let newRect = CGRect(x: 0.0, y: 0.0, width: scale * pageRect.size.width, height: scale * pageRect.size.height)

        UIGraphicsBeginImageContextWithOptions(newRect.size, true, 1)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

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

        defer { UIGraphicsEndImageContext() }
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return nil }

        return image
    }
}
