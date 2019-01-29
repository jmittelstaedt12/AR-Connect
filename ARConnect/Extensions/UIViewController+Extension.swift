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
        //        self.present(alert, animated: true, completion: nil)
    }
    
    // Dismiss keyboard when tapping view
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

}

extension UIViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}
