//
//  LoginView.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 7/11/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

protocol LoginViewDelegate: AnyObject {
    func signUp()
}

final class LoginView: UIView, KeyboardHandler {

    var keyboardWillShow = true
    var keyboardWillHide = false
    var keyboardWillShowObserver: NSObjectProtocol?
    var keyboardWillHideObserver: NSObjectProtocol?

    weak var delegate: LoginViewDelegate?

    let logoImageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "ar_connect_logo")
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    let arConnectLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "AR Connect"
        lbl.font = lbl.font.withSize(40)
        lbl.textAlignment = NSTextAlignment.center
        lbl.textColor = .white
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    let emailTextField: JMTextField = {
        let textField = JMTextField()
        textField.placeholder = "Email"
        textField.textColor = .black
        textField.backgroundColor = .white
        textField.textAlignment = NSTextAlignment.center
        textField.layer.cornerRadius = 5
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    let passwordTextField: JMTextField = {
        let textField = JMTextField()
        textField.placeholder = "Password"
        textField.textColor = .black
        textField.backgroundColor = .white
        textField.isSecureTextEntry = true
        textField.textAlignment = NSTextAlignment.center
        textField.layer.cornerRadius = 5
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    let logInButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Log in", for: .normal)
        btn.setTitleColor(UIColor.black, for: .normal)
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 20
        btn.translatesAutoresizingMaskIntoConstraints = false
        //        btn.addTarget(self, action: #selector(logIn), for: .touchUpInside)
        return btn
    }()

    let signUpLabel: UILabel = {
        let label = UILabel()
        label.text = "Don't have an account?"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .lightGray
        return label
    }()

    let signUpButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Sign up", for: .normal)
        btn.setTitleColor(ColorConstants.secondaryColor, for: .normal)
        btn.backgroundColor = .clear
        //        btn.layer.cornerRadius = 20
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    lazy var signUpStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [signUpLabel, signUpButton])
        view.axis = .horizontal
        view.distribution = .fill
        view.alignment = .fill
        view.spacing = 5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    @objc private func signUp() {
        delegate?.signUp()
    }

    deinit {
        if let keyboardWillShow = keyboardWillShowObserver {
            NotificationCenter.default.removeObserver(keyboardWillShow)
        }
        if let keyboardWillHide = keyboardWillHideObserver {
            NotificationCenter.default.removeObserver(keyboardWillHide)
        }
    }
}
extension LoginView: ProgrammaticUI {
    func setupView() {
        emailTextField.delegate = self
        passwordTextField.delegate = self
        signUpButton.addTarget(self, action: #selector(signUp), for: .touchUpInside)

        backgroundColor = ColorConstants.primaryColor

        hideKeyboardWhenTappedAround()
        startObservingKeyboardChanges()
        addSubviews()
        setSubviewAutoLayoutConstraints()
    }

    func addSubviews() {
        addSubview(logoImageView)
        addSubview(arConnectLabel)
        addSubview(emailTextField)
        addSubview(passwordTextField)
        addSubview(logInButton)
        addSubview(signUpStackView)
    }

    /// Set auto layout anchors for all subviews
    func setSubviewAutoLayoutConstraints() {
        // set x, y, width, and height constraints for arConnectLabel
        logoImageView.dimensionAnchors(height: 150, width: 150)
        logoImageView.edgeAnchors(top: safeAreaLayoutGuide.topAnchor,
                                  padding: UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0))
        logoImageView.centerAnchors(centerX: centerXAnchor)

        arConnectLabel.edgeAnchors(top: logoImageView.bottomAnchor,
                                   leading: safeAreaLayoutGuide.leadingAnchor,
                                   trailing: safeAreaLayoutGuide.trailingAnchor,
                                   padding: UIEdgeInsets(top: 0, left: 32, bottom: 0, right: -32))
        arConnectLabel.dimensionAnchors(height: 40)

        emailTextField.edgeAnchors(top: arConnectLabel.bottomAnchor,
                                   leading: safeAreaLayoutGuide.leadingAnchor,
                                   trailing: safeAreaLayoutGuide.trailingAnchor,
                                   padding: UIEdgeInsets(top: 30, left: 16, bottom: 0, right: -16))
        emailTextField.dimensionAnchors(height: 40)

        passwordTextField.edgeAnchors(top: emailTextField.bottomAnchor,
                                      leading: safeAreaLayoutGuide.leadingAnchor,
                                      trailing: safeAreaLayoutGuide.trailingAnchor,
                                      padding: UIEdgeInsets(top: 16, left: 16, bottom: 0, right: -16))
        passwordTextField.dimensionAnchors(height: 40)

        logInButton.edgeAnchors(top: passwordTextField.bottomAnchor,
                                padding: UIEdgeInsets(top: 32, left: 0, bottom: 0, right: 0))
        logInButton.dimensionAnchors(width: passwordTextField.widthAnchor, widthMultiplier: 2/5)
        logInButton.dimensionAnchors(height: 50)
        logInButton.centerAnchors(centerX: centerXAnchor)

        signUpStackView.edgeAnchors(bottom: safeAreaLayoutGuide.bottomAnchor,
                                    padding: UIEdgeInsets(top: 0, left: 0, bottom: -20, right: 0))
        signUpStackView.centerAnchors(centerX: centerXAnchor)
        //        signUpButton.edgeAnchors(leading: signUpLabel.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor,
        //                                 padding: UIEdgeInsets(top: 0, left: 0, bottom: -16, right: 0))
        //        signUpButton.dimensionAnchors(width: passwordTextField.widthAnchor, widthMultiplier: 3/5)
        //        signUpButton.dimensionAnchors(height: 40)
        //        signUpButton.centerAnchors(centerX: view.centerXAnchor)
    }
}
