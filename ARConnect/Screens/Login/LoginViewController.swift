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

final class LoginViewController: UIViewController, ControllerProtocol {

    typealias ViewModelType = LoginViewModel

    var viewModel: ViewModelType!

    let disposeBag = DisposeBag()

    /// Read-only computed property for accessing LoginView contents
    var loginView: LoginView {
        return view as! LoginView
    }

    override func loadView() {
        self.view = LoginView()
        loginView.delegate = self
        loginView.setupView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AR Connect"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Log In", style: .plain, target: nil, action: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    func configure(with viewModel: ViewModelType) {
        loginView.emailTextField.rx.text.asObservable()
            .ignoreNil()
            .subscribe(viewModel.input.email)
            .disposed(by: disposeBag)

        loginView.passwordTextField.rx.text.asObservable()
            .ignoreNil()
            .subscribe(viewModel.input.password)
            .disposed(by: disposeBag)

        loginView.logInButton.rx.tap.asObservable()
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
}

extension LoginViewController: LoginViewDelegate {

    func signUp() {
        self.present(RegisterViewController(), animated: true, completion: nil)
    }
}
