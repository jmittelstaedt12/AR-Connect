//
//  UITextField+Extension.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 1/26/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

class JMTextField: UITextField {

    var padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

}
