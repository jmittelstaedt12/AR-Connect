//
//  ViewModelProtocol.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/12/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Foundation

protocol ViewModelProtocol: class {

    associatedtype Input
    associatedtype Output
    var input: Input { get }
    var output: Output { get }
    
}
