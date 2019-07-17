//
//  FirebaseReferenceMock.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/27/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Foundation
import Firebase
import RxSwift
import RxCocoa

protocol AuthType {
    var user: LocalUser? { get set }
    func createUser(withEmail email: String, password: String, completion: ((Result<LocalUser, Error>) -> ())?)
    func signIn(withEmail email: String, password: String, completion: ((Result<LocalUser, Error>) -> ())?)
    func signOut() throws
}

class MockAuth: AuthType {

    var user: LocalUser? = LocalUser(name: "Jacob Mittel", email: "jacob@gmail.com", uid: "S1HrJFwrwUalb37PzVHny6B5qry2")

    enum MockResponse {
        case pending, passed, failed
    }
    private(set) var mockResponse: MockResponse = .pending
    var willSucceed = true

    func createUser(withEmail email: String, password: String, completion: ((Result<LocalUser, Error>) -> ())? = nil) {
        switch willSucceed {
        case true:
            completion?(.success(LocalUser()))
            mockResponse = .passed
        case false:
            completion?(.failure(MockError()))
            mockResponse = .failed
        }
    }

    func signIn(withEmail email: String, password: String, completion: ((Result<LocalUser, Error>) -> ())? = nil) {
        switch willSucceed {
        case true:
            completion?(.success(LocalUser()))
            mockResponse = .passed
        case false:
            completion?(.failure(MockError()))
            mockResponse = .failed
        }
    }

    func signOut() throws {
        switch willSucceed {
        case true:
            mockResponse = .passed
        case false:
            mockResponse = .failed
        }
    }
}
