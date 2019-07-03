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

class LoginTest: QuickSpec {

    override func spec() {
        var user: LocalUser!
        var auth: JMAuth!
        var mockDatabase: [String: Any]!
        var referenceMock: DatabaseeReferenceMock!
        var firebase: Firebase!
        var client: FirebaseClient!
        var scheduler: TestScheduler!
        var disposeBag: DisposeBag!
        var loginViewModel: LoginViewModel!

        describe("logging in") {
            beforeEach {
                user = LocalUser(name: "Jacob Mittel", email: "jacob@gmail.com", uid: "S1HrJFwrwUalb37PzVHny6B5qry2")
                auth = JMAuth(mock: true, willFail: false, mockUser: user)
                mockDatabase =
                    ["S1HrJFwrwUalb37PzVHny6B5qry2":
                        ["connectedTo": "",
                         "email": "jacob@gmail.com",
                         "isConnected": false,
                         "isOnline": true,
                         "isPending": false,
                         "latitude": 40.68776992071587,
                         "longitude": -73.92892530229798,
                         "name": "Jacob Mittel",
                         "pendingRequest": false,
                         "profileImageUrl": "https://firebasestorage.googleapis.com/v0/b/ar-connect.appspot.com/o/FF66F260-8C9B-4AC2-A604-B0BA9D2ED8D7.png?alt=media&token=6220e672-22b5-4abb-9fb3-756c0e3ef8ff",
                         "requestingUser":
                            ["latitude": 0.0,
                             "longitude": 0.0,
                             "uid": ""
                            ]
                        ]
                ]
                DatabaseeReferenceMock.initializeDatabase(mockDatabaseDictionary: mockDatabase)
                referenceMock = DatabaseeReferenceMock(pointsTo: [])
                firebase = Firebase(auth: auth, usersRef: referenceMock)
                client = FirebaseClient(firebase: firebase)
                loginViewModel = LoginViewModel(firebaseClient: client)
                scheduler = TestScheduler(initialClock: 0)
                disposeBag = DisposeBag()
            }
            context("no values in fields") {
                it("should not login on submit") {
                    let emailTf = UITextField()
                    emailTf.rx.text.asObservable()
                        .ignoreNil()
                        .subscribe(loginViewModel.input.email)
                        .disposed(by: disposeBag)

                    let passwordTf = UITextField()
                    passwordTf.rx.text.asObservable()
                        .ignoreNil()
                        .subscribe(loginViewModel.input.password)
                        .disposed(by: disposeBag)

                }
            }
        }
    }
}
