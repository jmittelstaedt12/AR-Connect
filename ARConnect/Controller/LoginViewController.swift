//
//  LoginViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/9/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {

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
        
        view.backgroundColor = UIColor(r: 61, g: 91, b: 151)
        view.addSubview(arConnectLabel)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(logInButton)
        view.addSubview(signUpButton)
        setSubviewConstraints()
        
        title = "AR Connect"
        
        hideKeyboardWhenTappedAround()
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
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
    
    @objc private func logIn() {
        
        guard let email = emailTextField.text, !email.isEmpty, let password = passwordTextField.text, !password.isEmpty else {
            let alert = UIAlertController(title: "Error", message: "Please populate all fields", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        FBClient.logInToDB(email: email, password: password, controller: self)
    }
    
    @objc private func signUp() {
        self.navigationController?.pushViewController(RegisterViewController(), animated: true)
    }

}