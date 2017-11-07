//
//  UIImage+.swift
//  Bookbot
//
//  Created by Adrian on 7/11/17.
//  Copyright © 2017 Bookbot. All rights reserved.
//

import Foundation

extension UIImageView {
    @IBInspectable var animation: String? {
        set (newValue) {
            if let value = newValue {
                self.image = UIImage.animatedImageNamed(value, duration: self.value(forKey: "animationDuration") as! TimeInterval)
            }
        }
        get {
            return nil
        }
    }
}
