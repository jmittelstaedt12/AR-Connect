//
//  KeyboardHandler.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 7/11/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

protocol KeyboardHandler: AnyObject {
    var keyboardWillShow: Bool { get set }
    var keyboardWillHide: Bool { get set }
    var keyboardWillShowObserver: NSObjectProtocol? { get set }
    var keyboardWillHideObserver: NSObjectProtocol? { get set }
    func startObservingKeyboardChanges()
    func keyboardWillShow(notification: Notification)
    func keyboardWillHide(notification: Notification)
}

extension KeyboardHandler where Self: UIView {

    /// Add observers for keyboardWillShow and keyboardWillHide
    func startObservingKeyboardChanges() {
        keyboardWillShowObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification,
                                                                          object: nil, queue: nil) { (notification) in
                                                                            self.keyboardWillShow(notification: notification)
        }

        keyboardWillHideObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification,
                                                                          object: nil, queue: nil) { (notification) in
                                                                            self.keyboardWillHide(notification: notification)
        }
    }

    /// When keyboard appears, animate view upwards
    func keyboardWillShow(notification: Notification) {
        guard keyboardWillShow, let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
            self.frame = CGRect(x: self.frame.origin.x,
                                     y: self.frame.origin.y - 100,
                                     width: self.bounds.width,
                                     height: self.bounds.height)
        }, completion: nil)
        keyboardWillShow = false
        keyboardWillHide = true
    }

    /// When keyboard hides, animate view downwards
    func keyboardWillHide(notification: Notification) {
        guard keyboardWillHide, let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
            self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y + 100,
                                     width: self.bounds.width, height: self.bounds.height)
        }, completion: nil)
        keyboardWillHide = false
        keyboardWillShow = true
    }
}
