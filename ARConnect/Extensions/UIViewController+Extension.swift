//
//  UIViewController+Extension.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 1/26/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

extension UIViewController {

    // Creates UIAlertController and displays it over the current view hierarchy
    func createAndDisplayAlert(withTitle title: String, body: String) {
        let alert = UIAlertController(title: title, message: body, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        alert.show()
    }
}
