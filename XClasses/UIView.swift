//
//  UIView.swift
//  XClasses
//
//  Created by Adrian on 13/10/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit

class XUIButton: UIButton, ViewModelManagerDelegate
{
    var viewModel: ViewModelDelegate!

    func assignViewModelToView(viewModel: ViewModelDelegate)
    {
        self.viewModel = viewModel
        // TODO: Set image and text
        //        let properties = viewModel.properties
        //        if let imagePath = properties["image"]
        //        {
        //            imageView.contentMode = UIViewContentMode.scaleAspectFit
        //            Manager.shared.loadImage(with: URL(string: imagePath)!, into: imageView)
        //        }
    }
}

class XUIImageView: UIImageView, ViewModelManagerDelegate
{
    var viewModel: ViewModelDelegate!
}

extension UIView {

    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }

    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}
