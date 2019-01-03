//
//  RootViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/11/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase

class RootViewController: UIViewController {

    private var current: UIViewController
    
    init() {
        self.current = SplashViewController()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.current = SplashViewController()
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(current)
        current.view.frame = view.bounds
        view.addSubview(current.view)
        current.didMove(toParent: self)
    }
    
    // Displays the login screen
    // If there was no user signed in on last app close, this will display the login screen
    func showLoginScreen() {
        let new = UINavigationController(rootViewController: LoginViewController())
        addChild(new)
        new.view.frame = view.bounds
        view.addSubview(new.view)
        new.didMove(toParent: self)

        current.willMove(toParent: nil)
        current.view.removeFromSuperview()
        current.removeFromParent()
        
        current = new
    }
    
    // If a user signs in, display the main map screen
    func switchToMainScreen() {
        let mainScreen = UINavigationController(rootViewController: MainViewController())
        let transition = CATransition()
        transition.type = .fade
        transition.duration = 0.5
        mainScreen.view.layer.add(transition, forKey: nil)
        
        animateFadeTransition(to: mainScreen)
//        current.willMove(toParent: nil)
//        addChild(mainScreen)
//        self.animateFadeTransition(to: mainScreen)
//        self.current.removeFromParent()
//        mainScreen.didMove(toParent: self)
//        self.current = mainScreen
    }
    
    // If the user signs out, switch to the login screen
    func switchToLogout() {
        let logoutScreen = UINavigationController(rootViewController: LoginViewController())
        animateDismissTransition(to: logoutScreen)
    }
    
    // Animation for presenting main map screen
    private func animateFadeTransition(to new: UIViewController, completion: (() -> Void)? = nil){
        self.present(new, animated: false, completion: nil)
        //        current.willMove(toParent: nil)
//        addChild(new)
//        self.navigationController?.popViewController(animated: false)
//        self.navigationController?.pushViewController(new, animated: false)
//        self.current.removeFromParent()
//        new.didMove(toParent: self)
//        self.current = new
//        completion?()
//        transition(from: current, to: new, duration: 0.9, options: [.transitionCrossDissolve, .curveEaseOut], animations: {}) { (completed) in
//            self.current.removeFromParent()
//            new.didMove(toParent: self)
//            self.current = new
//            completion?()
//        }
    }
    
    // Animation for dismissing
    private func animateDismissTransition(to new: UIViewController, completion: (() -> Void)? = nil) {
        current.willMove(toParent: nil)
        addChild(new)
        
        transition(from: current, to: new, duration: 0.9, options: [], animations: {
            new.view.frame = self.view.bounds
        }) { completed in
            self.current.removeFromParent()
            new.didMove(toParent: self)
            self.current = new
            completion?()
        }
    }
}


extension UIViewController {
    
    // Creates UIAlertController and displays it over the current view hierarchy
    func createAndDisplayAlert(withTitle title: String, body: String) {
        let alert = UIAlertController(title: title, message: body, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension UIViewController: UITextFieldDelegate {
    
    // Dismiss keyboard when tapping view
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}

extension UIView {
    
    // Used to set auto layout anchors for UIView edges
    func edgeAnchors(top: NSLayoutYAxisAnchor? = nil, leading: NSLayoutXAxisAnchor? = nil, bottom: NSLayoutYAxisAnchor? = nil, trailing: NSLayoutXAxisAnchor? = nil, padding: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)){
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
    func centerAnchors(centerX: NSLayoutXAxisAnchor? = nil, centerY: NSLayoutYAxisAnchor? = nil){
        if let centerX = centerX {
            centerXAnchor.constraint(equalTo: centerX).isActive = true
        }
        if let centerY = centerY {
            centerYAnchor.constraint(equalTo: centerY).isActive = true
        }
    }
    
    // Used to set auto layout anchors for UIView width and height
    func dimensionAnchors(height: CGFloat? = nil, heightMultiplier: CGFloat = 1, width: CGFloat? = nil, widthMultiplier: CGFloat = 1){
        if let height = height{
            heightAnchor.constraint(equalToConstant: height*heightMultiplier).isActive = true
        }
        if let width = width {
            widthAnchor.constraint(equalToConstant: width*widthMultiplier).isActive = true
        }
    }
}
