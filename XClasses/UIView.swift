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
}

class XUIImageView: UIImageView, ViewModelManagerDelegate
{
    var viewModel = ViewModel() as ViewModelDelegate
}
