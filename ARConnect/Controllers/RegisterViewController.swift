//
//  ViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/9/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase

final class RegisterViewController: UIViewController, KeyboardHandler {

    var keyboardWillShow = true
    var keyboardWillHide = false
    var keyboardWillShowObserver: NSObjectProtocol?
    var keyboardWillHideObserver: NSObjectProtocol?

    let cancelButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "cancel"), for: .normal)
        btn.addTarget(self, action: #selector(onCancel), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .gray
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onImageViewTap)))
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    let inputsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let nameTextField: JMTextField = {
        let textField = JMTextField()
        textField.placeholder = "Username"
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    var nameSeparatorView: UIView?

    let emailTextField: JMTextField = {
        let textField = JMTextField()
        textField.placeholder = "Email"
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    var emailSeparatorView: UIView?

    let passwordTextField: JMTextField = {
        let textField = JMTextField()
        textField.placeholder = "Password"
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isSecureTextEntry = true
        return textField
    }()

    let registerButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = .lightGray
        btn.setTitle("Register", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btn.addTarget(self, action: #selector(handleRegister), for: .touchUpInside)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorConstants.primaryColor

        nameSeparatorView = createSeparatorView()
        emailSeparatorView = createSeparatorView()

        view.addSubview(cancelButton)
        view.addSubview(profileImageView)
        view.addSubview(inputsContainerView)
        view.addSubview(registerButton)
        inputsContainerView.addSubview(nameTextField)
        inputsContainerView.addSubview(emailTextField)
        inputsContainerView.addSubview(passwordTextField)

        setSubviewConstraints()

        hideKeyboardWhenTappedAround()

        nameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self

        startObservingKeyboardChanges()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func setSubviewConstraints() {

        // Set constraints for cancel button
        cancelButton.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, padding: UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 0))
        cancelButton.dimensionAnchors(height: 32, width: 32)

        // Set constraints for profile image view
        profileImageView.edgeAnchors(top: view.topAnchor, bottom: inputsContainerView.topAnchor, padding: UIEdgeInsets(top: 48, left: 0, bottom: -16, right: 0))
        profileImageView.centerAnchors(centerX: view.centerXAnchor)
        profileImageView.dimensionAnchors(width: profileImageView.heightAnchor)

        // Set constraints for input container view
        inputsContainerView.centerAnchors(centerX: view.centerXAnchor, centerY: view.centerYAnchor)
        inputsContainerView.dimensionAnchors(height: 150)
        inputsContainerView.dimensionAnchors(width: view.widthAnchor, widthConstant: -24)

        guard let nameSeparatorView = nameSeparatorView, let emailSeparatorView = emailSeparatorView else {
            print("Error creating separator views")
            return
        }
        inputsContainerView.addSubview(nameSeparatorView)
        inputsContainerView.addSubview(emailSeparatorView)

        // Set constraints for input container view subviews
        nameTextField.edgeAnchors(top: inputsContainerView.topAnchor, leading: inputsContainerView.leadingAnchor, padding: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0))
        nameTextField.dimensionAnchors(height: inputsContainerView.heightAnchor, heightMultiplier: 1 / 3, width: inputsContainerView.widthAnchor, widthConstant: -12)

        // Set constraints for separator view
        nameSeparatorView.edgeAnchors(top: nameTextField.bottomAnchor, leading: inputsContainerView.leadingAnchor)
        nameSeparatorView.dimensionAnchors(width: inputsContainerView.widthAnchor)
        nameSeparatorView.dimensionAnchors(height: 1)

        // Set constraints for email text field
        emailTextField.edgeAnchors(top: nameSeparatorView.bottomAnchor, leading: inputsContainerView.leadingAnchor)
        emailTextField.dimensionAnchors(height: inputsContainerView.heightAnchor, heightMultiplier: 1 / 3, width: inputsContainerView.widthAnchor, widthConstant: -12)

        // Set constraints for email separator view
        emailSeparatorView.edgeAnchors(top: emailTextField.bottomAnchor, leading: inputsContainerView.leadingAnchor)
        emailSeparatorView.dimensionAnchors(width: inputsContainerView.widthAnchor)
        emailSeparatorView.dimensionAnchors(height: 1)

        // Set constraints for password text field

        passwordTextField.edgeAnchors(top: emailSeparatorView.bottomAnchor, leading: inputsContainerView.leadingAnchor, padding: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0))
        passwordTextField.dimensionAnchors(height: inputsContainerView.heightAnchor, heightMultiplier: 1 / 3, width: inputsContainerView.widthAnchor, widthConstant: -12)

        // Set constraints for register button
        registerButton.centerAnchors(centerX: view.centerXAnchor)
        registerButton.edgeAnchors(top: inputsContainerView.bottomAnchor, padding: UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0))
        registerButton.dimensionAnchors(width: inputsContainerView.widthAnchor)
        registerButton.dimensionAnchors(height: 50)
    }

    /// Returns line separator views to be placed between text fields
    private func createSeparatorView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(red: 220, green: 220, blue: 220)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    @objc private func onImageViewTap() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }

    @objc private func onCancel() {
        self.dismiss(animated: true, completion: nil)
    }

    /// Request to register user in database
    @objc private func handleRegister() {
        guard let name = nameTextField.text, !name.isEmpty, let email = emailTextField.text, !email.isEmpty, let password = passwordTextField.text, !password.isEmpty else {
            createAndDisplayAlert(withTitle: "Error", body: "Please populate all fields")
            return
        }
        let image = profileImageView.image?.pngData()
        do {
            try FirebaseClient.createNewUser(name: name, email: email, password: password, pngData: image, handler: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
                AppDelegate.shared.rootViewController.switchToMainScreen()
            })
        } catch let error {
            createAndDisplayAlert(withTitle: "Error Creating New User", body: error.localizedDescription)
        }
    }

    deinit {
        if let keyboardWillShow = keyboardWillShowObserver { NotificationCenter.default.removeObserver(keyboardWillShow) }
        if let keyboardWillHide = keyboardWillHideObserver { NotificationCenter.default.removeObserver(keyboardWillHide) }
    }
}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[UIImagePickerController.InfoKey.init(rawValue: "UIImagePickerControllerEditedImage")] as? UIImage {
            profileImageView.image = image
        } else if let image = info[UIImagePickerController.InfoKey.init(rawValue: "UIImagePickerControllerOriginalImage")] as? UIImage {
            profileImageView.image = image
        }
        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

}

extension UIColor {
    convenience init(red: CGFloat, green: CGFloat, blue: CGFloat) {
        self.init(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
}
