//
//  UIImage+.swift
//  
//
//  Created by Adrian on 1/12/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit
import AssistantKit

extension Device
{
    static func scaleAsCGFloat() -> CGFloat
    {
        let scale = Device.scale

        switch scale
        {
            case .x1: return 1.0
            case .x2: return 2.0
            case .x3: return 3.0
            default:  return 2.0
        }
    }
}

extension CGPDFDocument
{
    func uiImageFromPDFPage(pageNumber: Int, size: CGSize, aspectFill: Bool = true) -> UIImage?
    {
        guard let page = page(at: pageNumber) else { return nil }

        // Determine the size of the PDF page.
        // TODO use proportional sizing below
        var pageRect = page.getBoxRect(.mediaBox)
        let widthRatio = Double(size.width) / Double(pageRect.size.width)
        let heightRatio = Double(size.height) / Double(pageRect.size.height)
        var scale: CGFloat = 1.0

        if aspectFill
        {
            scale = CGFloat(max(widthRatio, heightRatio))
        }
        else
        {
            scale = CGFloat(min(widthRatio, heightRatio))
        }

        scale *= Device.scaleAsCGFloat()

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

extension CGSize
{
    func proportionalSizing(to size: CGSize, contentMode: UIViewContentMode) -> CGSize
    {
        let width = Double(self.width)
        let height = Double(self.height)
        let widthRatio = Double(size.width) / width
        let heightRatio = Double(size.height) / height
        var scale: Double = 1.0

        switch contentMode
        {
        case .scaleAspectFit:
            scale = min(widthRatio, heightRatio)
        case .scaleAspectFill:
            scale = max(widthRatio, heightRatio)
        case .top:
            scale = widthRatio
        default:
            scale = min(widthRatio, heightRatio)
        }

        let newSize = CGSize(width: scale * width, height: scale * height)
        return newSize
    }
}

extension UILabel {
    func boundingRectForCharacterRange(range: NSRange) -> CGRect? {

        guard let attributedText = attributedText else { return nil }

        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()

        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(size: bounds.size)
        textContainer.lineFragmentPadding = 0.0

        layoutManager.addTextContainer(textContainer)

        var glyphRange = NSRange()

        // Convert the range for glyphs.
        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)

        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }
}
