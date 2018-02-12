//
//  UIImage+.swift
//  Bookbot
//
//  Created by Adrian on 7/11/17.
//  Copyright © 2017 Bookbot. All rights reserved.
//

import Foundation

extension UIImageView {
    @IBInspectable var animatedImageName: String? {
        set (value) {
            if let value = value {
                let animationImages = UIImage.animatedImageNamed(value, duration: 0.0)?.images
                self.animationImages = animationImages
                self.image = animationImages?.first
                self.animationDuration = Double(self.animationImages!.count) / 24
            }
        }

        get {
            return nil
        }
    }

    @IBInspectable var animationStart: Double {
        set (value) {
            Timer.scheduledTimer(withTimeInterval: value, repeats: false) { _ in
                self.startAnimating()
            }
        }

        get {
            return 0.0
        }
    }
}



