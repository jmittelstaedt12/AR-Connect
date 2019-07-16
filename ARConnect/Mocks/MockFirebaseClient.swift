//
//  MockFirebaseClient.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 7/15/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

// swiftlint:disable colon

import RxSwift
import Firebase

final class MockFirebaseClient: FirebaseClientType {

    var auth: AuthType!
    var usersRef: DatabaseReferenceType!

    enum MockResponse {
        case pending, passed, failed
    }
    private(set) var mockResponse: MockResponse = .pending
    var willSucceed = true

    init() {
        let firebase = Firebase(functionality: .mock)
        auth = firebase.auth
        usersRef = firebase.usersRef
    }

    func logInToDB(email: String, password: String) -> Observable<Result<LocalUser, Error>> {
        switch willSucceed {
        case true:
            mockResponse = .passed
        case false:
            mockResponse = .failed
        }
        return Observable.empty()
    }

    func setOnDisconnectUpdates(forUid uid: String) {
        switch willSucceed {
        case true:
            mockResponse = .passed
        case false:
            mockResponse = .failed
        }
    }

    func fetchObservableUser(forUid uid: String) -> Observable<LocalUser> {
        switch willSucceed {
        case true:
            mockResponse = .passed
        case false:
            mockResponse = .failed
        }
        return Observable.empty()
    }

    func createAmOnlineObservable() -> Observable<Bool> {
        switch willSucceed {
        case true:
            mockResponse = .passed
        case false:
            mockResponse = .failed
        }
        return Observable.empty()
    }

    func willDisplayRequestingUserObservable() -> Observable<(LocalUser, [String : AnyObject])>? {
        switch willSucceed {
        case true:
            mockResponse = .passed
        case false:
            mockResponse = .failed
        }
        return Observable.empty()
    }

    func logoutOfDB() throws {
        switch willSucceed {
        case true:
            mockResponse = .passed
        case false:
            mockResponse = .failed
        }
    }

    func createEndSessionObservable(forUid uid: String) -> Observable<Bool>? {
        switch willSucceed {
        case true:
            mockResponse = .passed
        case false:
            mockResponse = .failed
        }
        return Observable.empty()
    }

    func createCallUserObservable(forUid uid: String, atCoordinate coordinate: (latitude: Double, longitude: Double)) -> Observable<Bool> {
        switch willSucceed {
        case true:
            mockResponse = .passed
        case false:
            mockResponse = .failed
        }
        return Observable.empty()
    }

    func createUserOnlineObservable(forUid uid: String) -> Observable<Bool> {
        switch willSucceed {
        case true:
            mockResponse = .passed
        case false:
            mockResponse = .failed
        }
        return Observable.empty()
    }
}

// swiftlint:enable colon
