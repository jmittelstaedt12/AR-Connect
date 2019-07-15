//
//  ProgrammaticUI.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 7/11/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Foundation

protocol ProgrammaticUI: AnyObject {
    func setupView()
    func addSubviews()
    func setSubviewAutoLayoutConstraints()
}
