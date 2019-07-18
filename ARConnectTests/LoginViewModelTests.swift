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
        var client: MockFirebaseClient!
        var scheduler: TestScheduler!
        var disposeBag: DisposeBag!
        var subject: LoginViewModel!
        continueAfterFailure = false
        #error("add continue after failure elsewhere and see if it works")
        beforeEach {
            scheduler = TestScheduler(initialClock: 0)
            disposeBag = DisposeBag()

            client = MockFirebaseClient()
            subject = LoginViewModel(firebaseClient: client)
        }

        describe("logging in") {
            context("typed in credentials") {
                var credentialsEvents: [LoginViewModel.Credentials?]!
                beforeEach {
                    let scheduledObserver = scheduler.createObserver(LoginViewModel.Credentials.self)
                    subject.credentialsObservable.subscribe(scheduledObserver).disposed(by: disposeBag)
                    scheduler.scheduleAt(0, action: {
                        subject.input.email.onNext("Jacob@gmail.com")
                        subject.input.password.onNext("123456")
                    })
                    scheduler.start()
                    credentialsEvents = scheduledObserver.events.map { $0.value.element }
                }

                it("updates credentials observable") {
                    expect(credentialsEvents).toNot(beEmpty())
                    expect(credentialsEvents.first!?.email).to(equal("Jacob@gmail.com"))
                    expect(credentialsEvents.first!?.password).to(equal("123456"))
                }
            }

            context("submitted log in request") {
                beforeEach {
                    client.willSucceed = true
                    subject.input.email.onNext("Jacob@gmail.com")
                    subject.input.password.onNext("123456")
                    subject.input.signInDidTap.onNext(())
                }

                it("logs into the database") {
                    expect(client.mockResponse).to(equal(.passed))
                }
            }
        }
    }
}
