//
//  ControllerProtocol.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/12/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

protocol ControllerProtocol: class {

    associatedtype ViewModelType: ViewModelProtocol

    func configure(with viewModel: ViewModelType)
    static func create(with viewModel: ViewModelType) -> UIViewController
}
