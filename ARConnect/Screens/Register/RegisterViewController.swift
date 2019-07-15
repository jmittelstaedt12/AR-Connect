//
//  ViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/9/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase

final class RegisterViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    let firebaseClient: FirebaseClient

    /// Read-only computed property for accessing RegisterView contents
    var registerView: RegisterView {
        return view as! RegisterView
    }

    init(firebaseClient: FirebaseClient = FirebaseClient()) {
        self.firebaseClient = firebaseClient
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = RegisterView()
        registerView.delegate = self
        registerView.setupView()
    }
}

extension RegisterViewController: RegisterViewDelegate {
    func onImageViewTap(presentPicker picker: UIImagePickerController) {
        present(picker, animated: true, completion: nil)
    }

    func onCancel() {
        self.dismiss(animated: true, completion: nil)
    }

    /// Request to register user in database
    func handleRegister(firstName: String?, lastName: String?, email: String?, password: String?, imageData: Data?) {
        guard let firstName = firstName, !firstName.isEmpty, let lastName = lastName,
            !lastName.isEmpty, let email = email, !email.isEmpty, let password = password,
            !password.isEmpty else {
                createAndDisplayAlert(withTitle: "Error", body: "Please populate all fields")
                return
        }
        let registerUser = RegisterUser(firstName: firstName,
                                        lastName: lastName,
                                        email: email,
                                        password: password,
                                        pngData: imageData)
        firebaseClient.createNewUser(user: registerUser) { [weak self] error in
            if let error = error {
                self?.createAndDisplayAlert(withTitle: "Error", body: error.localizedDescription)
                return
            }
            self?.dismiss(animated: true, completion: nil)
            AppDelegate.shared.rootViewController.switchToMainScreen()
        }
    }

    func dismissImagePicker() {
        dismiss(animated: true, completion: nil)
    }
}
