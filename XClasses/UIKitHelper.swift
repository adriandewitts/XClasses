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

extension Device {
    static var scaleMultiplier: CGFloat {
        let scale = Device.scale

        switch scale {
            case .x1: return 1.0
            case .x2: return 2.0
            case .x3: return 3.0
            default:  return 2.0
        }
    }

    static var isSimulator: Bool {
        return ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
    }

    static var isDevice: Bool {
        return ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] == nil
    }
}

extension CGPDFDocument {
    func imageFromPage(number: Int, with size: CGSize, aspect: Aspect = .fill) -> UIImage? {
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

extension CGRect {
    mutating func expand(by: CGFloat) {
        origin.x -= by
        origin.y -= by
        size.width += 2 * by
        size.height += 2 * by
    }
}

extension CGSize {
    func resizingAndScaling(to size: CGSize, with aspect: Aspect = .fill) -> (CGSize, CGFloat) {
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

extension UIScrollView {
    func scrollRectToVisibleCenteredOn(visibleRect: CGRect, contentRect: CGRect, animated: Bool) {
        let centeredRect = CGRect(x: visibleRect.origin.x + (visibleRect.size.width / 2.0) - (contentRect.size.width / 2.0), y: visibleRect.origin.y + (visibleRect.size.height / 2.0) - (contentRect.size.height / 2.0), width: contentRect.size.width, height: contentRect.size.height)
        scrollRectToVisible(centeredRect, animated: animated)
    }
}

extension UIStoryboard {
    class func controller(_ identifier: String, storyboard: String = "Main") -> UIViewController {
        return UIStoryboard(name: storyboard, bundle: nil).instantiateViewController(withIdentifier: identifier)
    }
}

func screenSize() -> CGSize {
    return UIScreen.main.bounds.size
}
