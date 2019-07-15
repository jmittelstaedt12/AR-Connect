//
//  LoginTests.swift
//  ARConnectTests
//
//  Created by Jacob Mittelstaedt on 6/26/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Foundation
import Quick
import Nimble
import RxSwift
import RxBlocking
import RxTest

@testable import ARConnect

class LoginViewModelTests: QuickSpec {

    override func spec() {
        var client: FirebaseClient!
        var scheduler: TestScheduler!
        var disposeBag: DisposeBag!
        var loginViewModel: LoginViewModel!
        var emailTf: UITextField!
        var passwordTf: UITextField!
        var loginButton: UIButton!

        describe("logging in") {
            beforeEach {
                scheduler = TestScheduler(initialClock: 0)
                disposeBag = DisposeBag()

                client = FirebaseClient(firebase: Firebase(functionality: .mock))
                loginViewModel = LoginViewModel(firebaseClient: client)
                emailTf = UITextField()
                emailTf.rx.text.asObservable()
                    .ignoreNil()
                    .subscribe(loginViewModel.input.email)
                    .disposed(by: disposeBag)

                passwordTf = UITextField()
                passwordTf.rx.text.asObservable()
                    .ignoreNil()
                    .subscribe(loginViewModel.input.password)
                    .disposed(by: disposeBag)

                loginButton = UIButton()
                loginButton.rx.tap.asObservable()
                    .subscribe(loginViewModel.input.signInDidTap)
                    .disposed(by: disposeBag)
            }

            context("no values in fields") {
                it("should not login on submit") {
                    emailTf.insertText("email")
                    passwordTf.insertText("password")
                    loginButton.sendActions(for: .touchUpInside)
                    let scheduledObserver = scheduler.createObserver(LocalUser.self)
                    loginViewModel.output.loginResultObservable.subscribe(scheduledObserver).disposed(by: disposeBag)
                    expect(scheduledObserver.events).toNot(beEmpty())

                }
            }
        }
    }
}
