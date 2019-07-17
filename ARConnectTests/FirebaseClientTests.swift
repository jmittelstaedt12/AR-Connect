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
                usersRef.databaseInstance.database =
                ["Users":
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
                        ],
                     "n13XNUAEb1bIcZF57fqVE9BHEzo2":
                        ["connectedTo": "",
                         "email": "Kevin@gmail.com",
                         "isConnected": false,
                         "isOnline": true,
                         "isPending": false,
                         "latitude": 40.68404,
                         "longitude": -73.9259,
                         "name": "Kevin Nelson",
                         "pendingRequest": false,
                         "profileImageUrl": "https://firebasestorage.googleapis.com/v0/b/ar-connect.appspot.com/o/AF25B069-910D-4627-88E6-B1AEB7D6513E.png?alt=media&token=662d13fa-d0af-45eb-be9e-54a7f9be8779",
                         "requestingUser":
                            ["latitude": 0.0,
                             "longitude": 0.0,
                             "uid": ""
                            ]
                        ]
                    ]
                ]
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

            context("fetch users") {
                var userArrayEvents: [Recorded<Event<[LocalUser]>>] = []
                beforeEach {
                    let scheduledObserver = scheduler.createObserver([LocalUser].self)
                    client.fetchObservableUsers(withObservableType: .continuous)
                        .subscribe(scheduledObserver)
                        .disposed(by: disposeBag)
                    scheduler.start()
                    userArrayEvents = scheduledObserver.events
                }

                it("should provide users") {
                    expect(userArrayEvents).toNot(beEmpty())
                    expect(userArrayEvents.first?.value.element?.count).to(equal(1))
                    expect(userArrayEvents.first?.value.element?.first?.name).to(equal("Kevin Nelson"))
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

            context("get requesting user uid") {
                var requestingUserUidEvents: [Recorded<Event<String>>]!
                beforeEach {
                    let scheduledObserver = scheduler.createObserver(String.self)
                    client.createRequestingUserUidObservable()?
                        .subscribe(scheduledObserver)
                        .disposed(by: disposeBag)
                    scheduler.scheduleAt(10, action: {
                        usersRef.databaseInstance.database[keyPath: KeyPath("Users.S1HrJFwrwUalb37PzVHny6B5qry2.requestingUser")] =
                            [
                                "latitude": 10.0,
                                "longitude": 10.0,
                                "uid": "S1HrJFwrwUalb37PzVHny6B5qry2"
                        ]
                    })
                    scheduler.start()
                    requestingUserUidEvents = scheduledObserver.events
                }

                it("provides the uid of the requesting user") {
                    expect(requestingUserUidEvents).toNot(beEmpty())
                    expect(requestingUserUidEvents).to(equal([
                        .next(10, "S1HrJFwrwUalb37PzVHny6B5qry2")
                        ]))
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
                    expect(events).to(equal([
                        .next(0, true),
                        .next(10, false),
                        .next(20, false),
                        .next(30, false)
                    ]))
                }
            }

            context("user is online") {
                var willDisplayEvents: [Recorded<Event<(LocalUser, [String : AnyObject])>>]!
                beforeEach {
                    let scheduledObserver = scheduler.createObserver((LocalUser, [String: AnyObject]).self)
                    client.willDisplayRequestingUserObservable()?.subscribe(scheduledObserver).disposed(by: disposeBag)
                    scheduler.scheduleAt(0, action: {
                        usersRef.databaseInstance.database[keyPath: KeyPath("Users.S1HrJFwrwUalb37PzVHny6B5qry2.requestingUser")] =
                            [
                                "latitude": 10.0,
                                 "longitude": 10.0,
                                 "uid": "S1HrJFwrwUalb37PzVHny6B5qry2"
                            ]
                    })
                    scheduler.start()
                    willDisplayEvents = scheduledObserver.events
                }
                it("provides a local user and dictionary") {
                    expect(willDisplayEvents).toNot(beEmpty())
//                    expect(willDisplayEvents.first?.value.element).toNot(beNil())
//                    expect(willDisplayEvents.first?.value.element!.0.name).to(equal("Jacob Mittel"))
//                    expect(willDisplayEvents.first?.value.element!.1["latitude"]).to(beAKindOf(Double.self))
                }
            }
        }
    }
}

// swiftlint:enable function_body_length



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
