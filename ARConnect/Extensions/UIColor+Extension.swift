//
//  UIColor+Extension.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 7/14/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(red: CGFloat, green: CGFloat, blue: CGFloat) {
        self.init(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
}
