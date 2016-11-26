//
//  UIView.swift
//  XClasses
//
//  Created by Adrian on 13/10/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit

class XUIButton: UIButton, ViewModelDelegate
{
    var viewModel = ViewModel()
}

class XUIImageView: UIImageView, ViewModelDelegate
{
    var viewModel = ViewModel()
}
