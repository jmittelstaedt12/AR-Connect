//
//  UIAlertController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 1/26/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit.UIAlertController

extension UIAlertController {
    func show() {
        let win = UIWindow(frame: UIScreen.main.bounds)
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        win.rootViewController = viewController
        win.windowLevel = UIWindow.Level.alert + 1
        win.makeKeyAndVisible()
        viewController.present(self, animated: true, completion: nil)
    }
}
