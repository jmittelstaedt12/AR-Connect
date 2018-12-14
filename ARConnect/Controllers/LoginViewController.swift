//
//  LoginViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/9/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController, KeyboardHandler {

    var keyboardWillAnimate = true
    
    let arConnectLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "AR Connect"
        lbl.font = lbl.font.withSize(40)
        lbl.textAlignment = NSTextAlignment.center
        lbl.textColor = .white
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Username"
        tf.textColor = .black
        tf.backgroundColor = .white
        tf.textAlignment = NSTextAlignment.center
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.textColor = .black
        tf.backgroundColor = .white
        tf.isSecureTextEntry = true
        tf.textAlignment = NSTextAlignment.center
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    let logInButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Log in", for: .normal)
        btn.setTitleColor(UIColor.black, for: .normal)
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 5
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(logIn), for: .touchUpInside)
        return btn
    }()
    
    let signUpButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Sign up", for: .normal)
        btn.setTitleColor(UIColor.black, for: .normal)
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 5
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(signUp), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ColorConstants.primaryColor
        view.addSubview(arConnectLabel)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(logInButton)
        view.addSubview(signUpButton)
        setSubviewConstraints()
        
        title = "AR Connect"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Log In", style: .plain, target: nil, action: nil)
        
        hideKeyboardWhenTappedAround()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        startObservingKeyboardChanges()
    }
    
    /// Set auto layout anchors for all subviews
    private func setSubviewConstraints() {
        // set x, y, width, and height constraints for arConnectLabel
        arConnectLabel.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: UIEdgeInsets(top: 100, left: 32, bottom: 0, right: -32))
        arConnectLabel.dimensionAnchors(height: 40)
        emailTextField.edgeAnchors(top: arConnectLabel.bottomAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: UIEdgeInsets(top: 60, left: 16, bottom: 0, right: -16))
        emailTextField.dimensionAnchors(height: 40)
        passwordTextField.edgeAnchors(top: emailTextField.bottomAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: UIEdgeInsets(top: 16, left: 16, bottom: 0, right: -16))
        passwordTextField.dimensionAnchors(height: 40)
        logInButton.edgeAnchors(top: passwordTextField.bottomAnchor, padding: UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0))
        logInButton.dimensionAnchors(height: 40, width: view.frame.width, widthMultiplier: 1/3)
        logInButton.centerAnchors(centerX: view.centerXAnchor)
        signUpButton.edgeAnchors(top: logInButton.bottomAnchor, padding: UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0))
        signUpButton.dimensionAnchors(height: 40, width: view.frame.width, widthMultiplier: 1/3)
        signUpButton.centerAnchors(centerX: view.centerXAnchor)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        logInButton.isEnabled = false
        signUpButton.isEnabled = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        logInButton.isEnabled = true
        signUpButton.isEnabled = true
    }
    /// Request to login to database and segue into MainVC
    @objc private func logIn() {
        guard let email = emailTextField.text, !email.isEmpty, let password = passwordTextField.text, !password.isEmpty else {
            self.createAndDisplayAlert(withTitle: "Error", body: "Please populate all fields")
            return
        }
        FirebaseClient.logInToDB(email: email, password: password, controller: self)
    }
    
    @objc private func signUp() {
        self.navigationController?.pushViewController(RegisterViewController(), animated: true)
    }
}


protocol KeyboardHandler: class {
    var keyboardWillAnimate: Bool { get set }
    func startObservingKeyboardChanges()
    func keyboardWillShow(notification: Notification)
    func keyboardWillHide(notification: Notification)
}

extension KeyboardHandler where Self: UIViewController{
    
    /// Add observers for keyboardWillShow and keyboardWillHide
    func startObservingKeyboardChanges() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { (notification) in
            self.keyboardWillShow(notification: notification)
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { (notification) in
            self.keyboardWillHide(notification: notification)
        }
    }
    
    /// When keyboard appears, animate view upwards
    func keyboardWillShow(notification: Notification) {
        guard keyboardWillAnimate, let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double, let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }

        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
            self.view.frame = CGRect(x: self.view.frame.origin.x, y: self.view.frame.origin.y-100, width: self.view.bounds.width, height: self.view.bounds.height)
        }, completion: nil)
        keyboardWillAnimate = false
    }
    
    /// When keyboard hides, animate view downwards
    func keyboardWillHide(notification: Notification){
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double, let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
            self.view.frame = CGRect(x: self.view.frame.origin.x, y: self.view.frame.origin.y+100, width: self.view.bounds.width, height: self.view.bounds.height)
        }, completion: nil)
        keyboardWillAnimate = true
    }
}
