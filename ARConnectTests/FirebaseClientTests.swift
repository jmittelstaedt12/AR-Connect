//
//  FirebaseClientTests.swift
//  ARConnectTests
//
//  Created by Jacob Mittelstaedt on 6/28/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Quick
import Nimble
import RxSwift
import RxBlocking
import RxTest

@testable import ARConnect
// swiftlint:disable function_body_length

class FirebaseClientTests: QuickSpec {

    override func spec() {
//        var user: LocalUser!
//        var mockDatabase: [String: Any]!
        var firebase: Firebase!
        var usersRef: MockDatabaseReference!
        var client: FirebaseClient!
        var scheduler: TestScheduler!
        var disposeBag: DisposeBag!

        describe("network requests") {
            beforeEach {
                firebase = Firebase(functionality: .mock)
                usersRef = firebase.usersRef as? MockDatabaseReference
                client = FirebaseClient(firebase: firebase)
                scheduler = TestScheduler(initialClock: 0)
                disposeBag = DisposeBag()
            }

            context("firebase single event") {
                var snapshot: [String: Any]?
                beforeEach {
                    snapshot = try? client.rxFirebaseSingleEvent(forRef: firebase.usersRef, andEvent: .value)
                        .toBlocking(timeout: 1)
                        .last()?.value as? [String: Any]
                }
                it("should end sequence after event") {
                    expect(snapshot).toNot(beNil())
                }
                it("should return a dictionary") {
                    let user = snapshot?["S1HrJFwrwUalb37PzVHny6B5qry2"] as? [String: Any]
                    expect(user).toNot(beNil())
                }
            }

            context("firebase listener") {
                it("should not end sequence after event") {
                    let snapshot = try? client.rxFirebaseListener(forRef: firebase.usersRef, andEvent: .value)
                        .toBlocking(timeout: 1)
                        .last()?.value as? [String: Any]
                    expect(snapshot).to(beNil())
                }
            }

            context("fetch user") {
                it("should provide a user") {
                    let user = try? client.fetchObservableUser(forUid: "S1HrJFwrwUalb37PzVHny6B5qry2")
                        .toBlocking(timeout: 1)
                        .last()
                    expect(user?.name).to(equal("Jacob Mittel"))
                    expect(user?.email).to(equal("jacob@gmail.com"))
                    expect(user?.uid).to(equal("S1HrJFwrwUalb37PzVHny6B5qry2"))
                }
            }

            context("fetch requesting user") {
                it("should return a user from the database") {
                    let user = try? client.fetchRequestingUser(uid: "S1HrJFwrwUalb37PzVHny6B5qry2").toBlocking(timeout: 1).last()
                    expect(user?.0.name).to(equal("Jacob Mittel"))
                    expect(user?.0.email).to(equal("jacob@gmail.com"))
                    expect(user?.0.uid).to(equal("S1HrJFwrwUalb37PzVHny6B5qry2"))
                }
            }
            context("check if user is online") {
                it("should match user online status") {
                    let isOnline = client.createUserOnlineObservable(forUid: "S1HrJFwrwUalb37PzVHny6B5qry2")
                    let scheduledIsOnline = scheduler.createObserver(Bool.self)
                    isOnline.subscribe(scheduledIsOnline).disposed(by: disposeBag)
                    scheduler.scheduleAt(10, action: {
                        usersRef.databaseInstance.database[keyPath: KeyPath("Users.S1HrJFwrwUalb37PzVHny6B5qry2.isOnline")] = false
                    })
                    scheduler.start()
                    expect(scheduledIsOnline.events).to(equal([.next(0, true), .next(10, false)]))
                }
            }

            context("user is available") {
                var events: [Recorded<Event<Bool?>>] = []
                beforeEach {
                    let scheduledObserver = scheduler.createObserver(Bool?.self)
                    scheduler.scheduleAt(0, action: {
                        let isAvailable = try? client.createUserAvailableObservable(forUid: "S1HrJFwrwUalb37PzVHny6B5qry2")
                            .toBlocking(timeout: 1)
                            .last()
                        scheduledObserver.onNext(isAvailable!)
                    })
                    scheduler.scheduleAt(10, action: {
                        usersRef.databaseInstance.database[keyPath: KeyPath("Users.S1HrJFwrwUalb37PzVHny6B5qry2.isOnline")] = false
                        let isAvailable = try? client.createUserAvailableObservable(forUid: "S1HrJFwrwUalb37PzVHny6B5qry2")
                            .toBlocking(timeout: 1)
                            .last()
                        scheduledObserver.onNext(isAvailable!)
                    })
                    scheduler.scheduleAt(20, action: {
                        usersRef.databaseInstance.database[keyPath: KeyPath("Users.S1HrJFwrwUalb37PzVHny6B5qry2.isConnected")] = true
                        let isAvailable = try? client.createUserAvailableObservable(forUid: "S1HrJFwrwUalb37PzVHny6B5qry2")
                            .toBlocking(timeout: 1)
                            .last()
                        scheduledObserver.onNext(isAvailable!)
                    })
                    scheduler.scheduleAt(30, action: {
                        usersRef.databaseInstance.database[keyPath: KeyPath("Users.S1HrJFwrwUalb37PzVHny6B5qry2.pendingRequest")] = true
                        let isAvailable = try? client.createUserAvailableObservable(forUid: "S1HrJFwrwUalb37PzVHny6B5qry2")
                            .toBlocking(timeout: 1)
                            .last()
                        scheduledObserver.onNext(isAvailable!)
                    })
                    scheduler.start()
                    events = scheduledObserver.events
                }

                it("returns true") {
                    expect(events).to(equal([.next(0, true),
                                             .next(10, false),
                                             .next(20, false),
                                             .next(30, false)
                        ]))
                }
            }

//            context("calling user") {
//                it("should call if user is available") {
//                    let callUser = client.createCallUserObservable(forUid: "S1HrJFwrwUalb37PzVHny6B5qry2",
//                                                                   atCoordinate: (latitude: 0, longitude: 0))
//
//
//                }
//            }
//
//            context("call a user") {
//                it("should write to requesting user") {
//
//                }
//            }
//            context("observe requesting user") {
//                it("should return an observable of requesting user uid") {
//                    let observable = try? client.createRequestingUserUidObservable()
//                    let uid = try? observable?.toBlocking(timeout: 1).last()
//                    expect(uid).to(beNil())
//                }
//            }
        }
    }
}

// swiftlint:enable function_body_length





//                    var events: [Bool?]
//                    beforeEach {
//                        isA
//                        let scheduledObserver = scheduler.createObserver(Bool.self)
//                        isAvailable.subscribe(scheduledObserver).disposed(by: disposeBag)
//                        scheduler.scheduleAt(10, action: {
//                            usersRef.database[keyPath: KeyPath("S1HrJFwrwUalb37PzVHny6B5qry2.isOnline")] = false
//                            isAvailable = client.createUserAvailableObservable(forUid: "S1HrJFwrwUalb37PzVHny6B5qry2")
//                        })
//                        scheduler.start()
//                        events = scheduledObserver.events.map { $0.value.element }
//
//                    }
//                    expect(events)
//                        .to(equal([
//                            .next(0, true),
//                            .next(10, false),
//                        ]))
