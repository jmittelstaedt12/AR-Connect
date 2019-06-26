//
//  LoginViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/9/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase
import RxSwift

final class LoginViewController: UIViewController, KeyboardHandler, ControllerProtocol {

    typealias ViewModelType = LoginViewModel

    var viewModel: ViewModelType!

    var keyboardWillShow = true
    var keyboardWillHide = false
    var keyboardWillShowObserver: NSObjectProtocol?
    var keyboardWillHideObserver: NSObjectProtocol?

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
        btn.addTarget(self, action: #selector(signUp), for: .touchUpInside)
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

    let disposeBag = DisposeBag()

    func configure(with viewModel: ViewModelType) {
        emailTextField.rx.text.asObservable()
            .ignoreNil()
            .subscribe(viewModel.input.email)
            .disposed(by: disposeBag)

        passwordTextField.rx.text.asObservable()
            .ignoreNil()
            .subscribe(viewModel.input.password)
            .disposed(by: disposeBag)

        logInButton.rx.tap.asObservable()
            .subscribe(viewModel.input.signInDidTap)
            .disposed(by: disposeBag)

        viewModel.output.errorsObservable
            .subscribe(onNext: { [weak self] error in
                self?.createAndDisplayAlert(withTitle: "Error", body: error.localizedDescription)
            })
            .disposed(by: disposeBag)

        viewModel.output.loginResultObservable
            .subscribe(onNext: { _ in
                AppDelegate.shared.rootViewController.switchToMainScreen()
            })
            .disposed(by: disposeBag)

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorConstants.primaryColor
        view.addSubview(logoImageView)
        view.addSubview(arConnectLabel)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(logInButton)
        view.addSubview(signUpStackView)
        setSubviewConstraints()

        title = "AR Connect"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Log In", style: .plain, target: nil, action: nil)
        hideKeyboardWhenTappedAround()
        emailTextField.delegate = self
        passwordTextField.delegate = self

        startObservingKeyboardChanges()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    /// Set auto layout anchors for all subviews
    private func setSubviewConstraints() {
        // set x, y, width, and height constraints for arConnectLabel
        logoImageView.dimensionAnchors(height: 150, width: 150)
        logoImageView.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor,
                                  padding: UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0))
        logoImageView.centerAnchors(centerX: view.centerXAnchor)

        arConnectLabel.edgeAnchors(top: logoImageView.bottomAnchor,
                                   leading: view.safeAreaLayoutGuide.leadingAnchor,
                                   trailing: view.safeAreaLayoutGuide.trailingAnchor,
                                   padding: UIEdgeInsets(top: 0, left: 32, bottom: 0, right: -32))
        arConnectLabel.dimensionAnchors(height: 40)

        emailTextField.edgeAnchors(top: arConnectLabel.bottomAnchor,
                                   leading: view.safeAreaLayoutGuide.leadingAnchor,
                                   trailing: view.safeAreaLayoutGuide.trailingAnchor,
                                   padding: UIEdgeInsets(top: 30, left: 16, bottom: 0, right: -16))
        emailTextField.dimensionAnchors(height: 40)

        passwordTextField.edgeAnchors(top: emailTextField.bottomAnchor,
                                      leading: view.safeAreaLayoutGuide.leadingAnchor,
                                      trailing: view.safeAreaLayoutGuide.trailingAnchor,
                                      padding: UIEdgeInsets(top: 16, left: 16, bottom: 0, right: -16))
        passwordTextField.dimensionAnchors(height: 40)

        logInButton.edgeAnchors(top: passwordTextField.bottomAnchor,
                                padding: UIEdgeInsets(top: 32, left: 0, bottom: 0, right: 0))
        logInButton.dimensionAnchors(width: passwordTextField.widthAnchor, widthMultiplier: 2/5)
        logInButton.dimensionAnchors(height: 50)
        logInButton.centerAnchors(centerX: view.centerXAnchor)

        signUpStackView.edgeAnchors(bottom: view.safeAreaLayoutGuide.bottomAnchor,
                                    padding: UIEdgeInsets(top: 0, left: 0, bottom: -20, right: 0))
        signUpStackView.centerAnchors(centerX: view.centerXAnchor)
//        signUpButton.edgeAnchors(leading: signUpLabel.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor,
//                                 padding: UIEdgeInsets(top: 0, left: 0, bottom: -16, right: 0))
//        signUpButton.dimensionAnchors(width: passwordTextField.widthAnchor, widthMultiplier: 3/5)
//        signUpButton.dimensionAnchors(height: 40)
//        signUpButton.centerAnchors(centerX: view.centerXAnchor)
    }

    @objc private func signUp() {
        self.present(RegisterViewController(), animated: true, completion: nil)
    }

    deinit {
        print("login vc deinit")
        if let keyboardWillShow = keyboardWillShowObserver {
            NotificationCenter.default.removeObserver(keyboardWillShow)
        }
        if let keyboardWillHide = keyboardWillHideObserver {
            NotificationCenter.default.removeObserver(keyboardWillHide)
        }
    }
}

protocol KeyboardHandler: class {
    var keyboardWillShow: Bool { get set }
    var keyboardWillHide: Bool { get set }
    var keyboardWillShowObserver: NSObjectProtocol? { get set }
    var keyboardWillHideObserver: NSObjectProtocol? { get set }
    func startObservingKeyboardChanges()
    func keyboardWillShow(notification: Notification)
    func keyboardWillHide(notification: Notification)
}

extension KeyboardHandler where Self: UIViewController {

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
            self.view.frame = CGRect(x: self.view.frame.origin.x,
                                     y: self.view.frame.origin.y - 100,
                                     width: self.view.bounds.width,
                                     height: self.view.bounds.height)
        }, completion: nil)
        keyboardWillShow = false
        keyboardWillHide = true
    }

    /// When keyboard hides, animate view downwards
    func keyboardWillHide(notification: Notification) {
        guard keyboardWillHide,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
            self.view.frame = CGRect(x: self.view.frame.origin.x, y: self.view.frame.origin.y + 100,
                                     width: self.view.bounds.width, height: self.view.bounds.height)
        }, completion: nil)
        keyboardWillHide = false
        keyboardWillShow = true
    }
}
