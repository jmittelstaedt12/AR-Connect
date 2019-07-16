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

    struct Input {
        let email: AnyObserver<String>
        let password: AnyObserver<String>
        let signInDidTap: AnyObserver<Void>
    }

    struct Output {
        let didLogInObservable: Observable<LocalUser>
        let errorsObservable: Observable<Error>
    }

    let input: Input
    let output: Output

    private let emailSubject = PublishSubject<String>()
    private let passwordSubject = PublishSubject<String>()
    private let signInDidTapSubject = PublishSubject<Void>()
    private let didLogInSubject = PublishSubject<LocalUser>()
    private let errorsSubject = PublishSubject<Error>()
    private let disposeBag = DisposeBag()

    typealias Credentials = (email: String, password: String)
    let firebaseClient: FirebaseClientType

    let credentialsObservable: Observable<Credentials>

    init(firebaseClient: FirebaseClientType = FirebaseClient()) {
        input = Input(email: emailSubject.asObserver(),
                      password: passwordSubject.asObserver(),
                      signInDidTap: signInDidTapSubject.asObserver())

        output = Output(didLogInObservable: didLogInSubject,
                        errorsObservable: errorsSubject)

        self.firebaseClient = firebaseClient

        credentialsObservable = Observable.combineLatest(emailSubject.asObservable(), passwordSubject.asObservable()) { (email, password) in
            return Credentials(email: email, password: password)
        }

        setNetworkObservers()
    }

    private func setNetworkObservers() {
        signInDidTapSubject
            .withLatestFrom(credentialsObservable)
            .flatMapLatest { [weak self] credentials -> Observable<Result<LocalUser, Error>> in
                guard let self = self else { return Observable.empty() }
//                print("credentials: ", credentials)
                return self.firebaseClient.logInToDB(email: credentials.email, password: credentials.password)
            }
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let user):
                    self.didLogInSubject.onNext(user)
                case .failure(let error):
                    self.errorsSubject.onNext(error)
                }
            })
            .disposed(by: disposeBag)
    }
}
