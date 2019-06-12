//
//  UIView+Extension.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 1/26/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

extension UIView {

    // Used to set auto layout anchors for UIView edges
    func edgeAnchors(top: NSLayoutYAxisAnchor? = nil, leading: NSLayoutXAxisAnchor? = nil, bottom: NSLayoutYAxisAnchor? = nil, trailing: NSLayoutXAxisAnchor? = nil, padding: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)) {
        if let top = top {
            topAnchor.constraint(equalTo: top, constant: padding.top).isActive = true
        }
        if let leading = leading {
            leadingAnchor.constraint(equalTo: leading, constant: padding.left).isActive = true
        }
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: padding.bottom).isActive = true
        }
        if let trailing = trailing {
            trailingAnchor.constraint(equalTo: trailing, constant: padding.right).isActive = true
        }
    }

    // Usex to set auto layout anchors for UIView center coordinates
    func centerAnchors(centerX: NSLayoutXAxisAnchor? = nil, centerY: NSLayoutYAxisAnchor? = nil) {
        if let centerX = centerX {
            centerXAnchor.constraint(equalTo: centerX).isActive = true
        }
        if let centerY = centerY {
            centerYAnchor.constraint(equalTo: centerY).isActive = true
        }
    }

    // Used to set auto layout anchors for UIView width and height
    func dimensionAnchors(height: CGFloat? = nil, heightMultiplier: CGFloat = 1, width: CGFloat? = nil, widthMultiplier: CGFloat = 1) {
        if let height = height {
            heightAnchor.constraint(equalToConstant: height * heightMultiplier).isActive = true
        }
        if let width = width {
            widthAnchor.constraint(equalToConstant: width * widthMultiplier).isActive = true
        }
    }

    func dimensionAnchors(height: NSLayoutDimension? = nil, heightMultiplier: CGFloat = 1, heightConstant: CGFloat = 0, width: NSLayoutDimension? = nil, widthMultiplier: CGFloat = 1, widthConstant: CGFloat = 0) {
        if let height = height {
            heightAnchor.constraint(equalTo: height, multiplier: heightMultiplier, constant: heightConstant).isActive = true
        }
        if let width = width {
            widthAnchor.constraint(equalTo: width, multiplier: widthMultiplier, constant: widthConstant).isActive = true
        }
    }

    func rotate(_ degrees: CGFloat, duration: Double = 0.1, _ completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.transform = CGAffineTransform(rotationAngle: degrees)
        }, completion: { _ in completion?() })
    }
}
