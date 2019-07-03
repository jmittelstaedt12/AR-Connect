//
//  FirebaseClientTests.swift
//  ARConnectTests
//
//  Created by Jacob Mittelstaedt on 6/28/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Foundation
import Quick
import Nimble
import RxSwift
import RxBlocking
import RxTest

@testable import ARConnect

class FirebaseClientTests: QuickSpec {

    override func spec() {
        var user: LocalUser!
        var auth: JMAuth!
        var mockDatabase: [String: Any]!
        var referenceMock: DatabaseeReferenceMock!
        var firebase: Firebase!
        var client: FirebaseClient!
        var scheduler: TestScheduler!
        var disposeBag: DisposeBag!

        describe("network requests") {
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
                scheduler = TestScheduler(initialClock: 0)
                disposeBag = DisposeBag()
            }

            context("firebase single event") {
                var snapshot: [String: Any]?
                beforeEach {
                    snapshot = try? client.rxFirebaseSingleEvent(forRef: referenceMock, andEvent: .value)
                        .toBlocking(timeout: 1)
                        .last()?.value as? [String: Any]
                }
                it("should end sequence after event") {
                    expect(snapshot).toNot(beNil())
                }
                it("should have a dictionary") {
                    let user = snapshot?["S1HrJFwrwUalb37PzVHny6B5qry2"] as? [String: Any]
                    expect(user).toNot(beNil())
                }
            }

            context("firebase listener") {
                it("should not end sequence after event") {
                    let snapshot = try? client.rxFirebaseListener(forRef: referenceMock, andEvent: .value).toBlocking(timeout: 1).last()?.value as? [String: Any]
                    expect(snapshot).to(beNil())
                }
            }

            context("fetch user") {
                it("should provide a user") {
                    let user = try? client.fetchObservableUser(forUid: "S1HrJFwrwUalb37PzVHny6B5qry2").toBlocking(timeout: 1).last()
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
                        client.usersRef.child("S1HrJFwrwUalb37PzVHny6B5qry2").updateChildValues(["isOnline": false])
                    })
                    scheduler.scheduleAt(20, action: {
                        client.usersRef.child("S1HrJFwrwUalb37PzVHny6B5qry2").updateChildValues(["isOnline": true])
                    })
                    scheduler.start()
                    expect(scheduledIsOnline.events).to(equal([
                        .next(0, true),
                        .next(10, false),
                        .next(20, true)
                    ]))
                }
            }

            context("check if user is available") {
                it("should match user availability") {
                    client.usersRef.child("S1HrJFwrwUalb37PzVHny6B5qry2").updateChildValues(["isOnline": true,
                                                                                             "isConnected": false,
                                                                                             "pendingRequest": true])
                    let isAvailable = client.createUserAvailableObservable(forUid: "S1HrJFwrwUalb37PzVHny6B5qry2")
                    let scheduledIsAvailable = scheduler.createObserver(Bool.self)
                    isAvailable.subscribe(scheduledIsAvailable).disposed(by: disposeBag)
                    scheduler.start()
                    expect(scheduledIsAvailable.events)
                        .to(equal([
                            .next(0, false),
                            .completed(0)
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
