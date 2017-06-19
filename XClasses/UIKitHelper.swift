//
//  UIImage+.swift
//  
//
//  Created by Adrian on 1/12/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit
import AssistantKit

enum Aspect {
    case fit
    case fill
}

extension Device
{
    static var scaleMultiplier: CGFloat
    {
        let scale = Device.scale

        switch scale {
            case .x1: return 1.0
            case .x2: return 2.0
            case .x3: return 3.0
            default:  return 2.0
        }
    }
}

extension CGPDFDocument
{
    func imageFromPage(number: Int, with size: CGSize, aspect: Aspect = .fill) -> UIImage?
    {
        guard let page = page(at: number) else {
            return nil
        }

        let pageRect = page.getBoxRect(.mediaBox)
        let (newSize, scale) = pageRect.size.resizingAndScaling(to: size, with: aspect)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: CGPoint.zero, size: newSize))
            context.cgContext.translateBy(x: 0, y: newSize.height)
            context.cgContext.scaleBy(x: scale, y: -scale)
            context.cgContext.drawPDFPage(page)
        }

        return image
    }

    func sizeOfPage(number: Int) -> CGSize? {
        guard let page = page(at: number) else {
            return nil
        }

        return page.getBoxRect(.mediaBox).size
    }
}

extension CGSize {
    func resizingAndScaling(to size: CGSize, with aspect: Aspect = .fill) -> (CGSize, CGFloat)
    {
        // Have to make these Doubles because we use min and max which expects them
        let width = Double(self.width)
        let height = Double(self.height)
        let widthRatio = Double(size.width) / width
        let heightRatio = Double(size.height) / height
        var scale: Double = 1.0

        if aspect == .fill {
            scale = max(widthRatio, heightRatio)
        }
        else {
            scale = min(widthRatio, heightRatio)
        }

        return (CGSize(width: scale * width, height: scale * height), CGFloat(scale))
    }
}

extension CGPoint {
    func scaling(by: CGFloat) -> CGPoint {
        return CGPoint(x: x * by, y: y * by)
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
