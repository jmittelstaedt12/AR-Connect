//
//  MainViewModelTests.swift
//  ARConnectTests
//
//  Created by Jacob Mittelstaedt on 7/16/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

// swiftlint:disable function_body_length

import Quick
import Nimble
import RxSwift
import RxBlocking
import RxTest

@testable import ARConnect

final class MainViewModelTests: QuickSpec {

    override func spec() {
        var client: MockFirebaseClient!
        var scheduler: TestScheduler!
        var disposeBag: DisposeBag!
        var subject: MainViewModel!

        beforeEach {
            scheduler = TestScheduler(initialClock: 0)
            disposeBag = DisposeBag()

            client = MockFirebaseClient()
            subject = MainViewModel(firebaseClient: client)
        }

//        describe("user authentication status") {
//            context("user is authenticated") {
//                var authenticatedEvents: [Recorded<Event<Result<String, FirebaseError>>>]!
//                beforeEach {
//                    let scheduledObserver = scheduler.createObserver(Result<String, FirebaseError>.self)
//                    subject.output.authenticatedUserObservable.subscribe(scheduledObserver).disposed(by: disposeBag)
//                    scheduler.scheduleAt(10, action: {
//                        client.auth.user = nil
//                    })
//                    scheduler.start()
//                    authenticatedEvents = scheduledObserver.events
//                }
//
//                it("notifies authenticated observable") {
//                    expect(authenticatedEvents).to(equal(
//                        [
//                            .next(0, .success("mock")),
//                            .next(10, .failure(.amOffline))
//                        ]
//                    ))
//                }
//            }
//        }

        describe("connect request from other user") {
            context("preparing view to display connect request") {
            }
        }

        describe("user logged out") {
            context("user tapped log out") {
                var events: [Recorded<Event<Void>>]!
                beforeEach {
                    let scheduledObserver = scheduler.createObserver(Void.self)
                    subject.output.endSessionObservable.subscribe(scheduledObserver).disposed(by: disposeBag)
                    scheduler.start()
                    subject.input.disconnectRequest.onNext(())
                    events = scheduledObserver.events
                }

                it("notifies view of log out") {
                    expect(events).toNot(beEmpty())
                }
            }
        }
    }
}

// swiftlint:enable function_body_length
