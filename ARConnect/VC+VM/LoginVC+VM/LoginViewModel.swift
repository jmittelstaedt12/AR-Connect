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
        let loginResultObservable: Observable<LocalUser>
        let errorsObservable: Observable<Error>
    }

    let input: Input
    let output: Output

    private let emailSubject = PublishSubject<String>()
    private let passwordSubject = PublishSubject<String>()
    private let signInDidTapSubject = PublishSubject<Void>()
    private let loginResultSubject = PublishSubject<LocalUser>()
    private let errorsSubject = PublishSubject<Error>()
    private let disposeBag = DisposeBag()

    typealias Credentials = (email: String, password: String)
    let firebaseClient: FirebaseClient
    
    var credentialsObservable: Observable<Credentials> {
        return Observable.combineLatest(emailSubject.asObservable(), passwordSubject.asObservable()) { (email, password) in
            return Credentials(email: email, password: password)
        }
    }
    
    init(firebaseClient: FirebaseClient = FirebaseClient()) {
        input = Input(email: emailSubject.asObserver(),
                      password: passwordSubject.asObserver(),
                      signInDidTap: signInDidTapSubject.asObserver())

        output = Output(loginResultObservable: loginResultSubject.asObservable(),
                        errorsObservable: errorsSubject.asObservable())

        self.firebaseClient = firebaseClient

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
