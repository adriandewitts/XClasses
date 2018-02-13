//
//  UIImage+.swift
//  Bookbot
//
//  Created by Adrian on 7/11/17.
//  Copyright © 2017 Bookbot. All rights reserved.
//

import Foundation
import APNGKit

extension APNGImageView {
    @IBInspectable var animationName: String? {
        set (value) {
            if let value = value {
                self.image = APNGImage(named: value, progressive: true)
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


