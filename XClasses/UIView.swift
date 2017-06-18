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
    var viewModel = ViewModel() as ViewModelDelegate

    func assignViewModelToView(viewModel: ViewModelDelegate)
    {
        self.viewModel = viewModel
        // TODO: Set image and text
        //        let properties = viewModel.properties
        //        if let imagePath = properties["image"]
        //        {
        //            imageView.contentMode = UIViewContentMode.scaleAspectFit
        //            Nuke.loadImage(with: URL(string: imagePath)!, into: imageView)
        //        }
    }
}

class XUIImageView: UIImageView, ViewModelManagerDelegate
{
    var viewModel = ViewModel() as ViewModelDelegate
}
