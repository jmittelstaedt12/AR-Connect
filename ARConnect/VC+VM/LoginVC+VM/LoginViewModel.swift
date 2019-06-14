//
//  LoginViewModel.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/13/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Foundation
import RxSwift
import Firebase

class LoginViewModel: ViewModelProtocol {

    typealias Credentials = (email: String, password: String)

    struct Input {
        let email: AnyObserver<String>
        let password: AnyObserver<String>
        let signInDidTap: AnyObserver<Void>
    }

    struct Output {
        let loginResultObservable: Observable<AuthDataResult>
        let errorsObservable: Observable<Error>
    }

    let input: Input
    let output: Output

    private let emailSubject = PublishSubject<String>()
    private let passwordSubject = PublishSubject<String>()
    private let signInDidTapSubject = PublishSubject<Void>()
    private let loginResultSubject = PublishSubject<AuthDataResult>()
    private let errorsSubject = PublishSubject<Error>()
    private let disposeBag = DisposeBag()

    private var credentialsObservable: Observable<Credentials> {
        return Observable.combineLatest(emailSubject.asObservable(), passwordSubject.asObservable()) { (email, password) in
            return Credentials(email: email, password: password)
        }
    }

    init() {
        input = Input(email: emailSubject.asObserver(),
                      password: passwordSubject.asObserver(),
                      signInDidTap: signInDidTapSubject.asObserver())

        output = Output(loginResultObservable: loginResultSubject.asObserver(),
                        errorsObservable: errorsSubject.asObserver())

        setNetworkObservers()
    }

    private func setNetworkObservers() {
        signInDidTapSubject
            .withLatestFrom(credentialsObservable)
            .flatMapLatest { credentials in
//                print("credentials: ", credentials)
                return FirebaseClient.logInToDB(email: credentials.email, password: credentials.password)
            }
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .success(let data):
                    self?.loginResultSubject.onNext(data)
                case .failure(let error):
                    self?.errorsSubject.onNext(error)
                }
            })
            .disposed(by: disposeBag)
    }
}
