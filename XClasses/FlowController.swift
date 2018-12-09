//
//  FlowController.swift
//  Bookbot
//
//  Created by Adrian DeWitts on 9/12/18.
//  Copyright © 2018 Bookbot. All rights reserved.
//

import UIKit

/// Makes sure the controller class conforms to ViewModelManagerDelegate so thge flow controller can automatically populate its ViewModel.
protocol ViewModelManagerDelegate {
    var viewModel: ViewModelDelegate! { get set }
}

/** The Flow Controller is the class that moves the ViewModel from one screen to the other.
 - **Requirements** The first ViewModel has to be set before the ViewModel is accessed.
 */
class FlowController: ViewModelManagerDelegate {
    static let shared = FlowController()
    var viewModel: ViewModelDelegate!
    var transitionImage: UIImage?
    
    class var viewModel: ViewModelDelegate {
        get {
            return FlowController.shared.viewModel
        }
        set(viewModel) {
            FlowController.shared.viewModel = viewModel
        }
    }
    
    class var hasViewModel: Bool {
        if FlowController.shared.viewModel != nil {
            return true
        }
        return false
    }
}
