//
//  ControllerProtocol.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/12/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

protocol ControllerProtocol where Self:UIViewController {

    associatedtype ViewModelType: ViewModelProtocol
    var viewModel: ViewModelType! { get set }
    func configure(with viewModel: ViewModelType)
}

extension ControllerProtocol {

    init(viewModel: ViewModelType) {
        self.init()
        self.viewModel = viewModel
        configure(with: viewModel)
    }
}
