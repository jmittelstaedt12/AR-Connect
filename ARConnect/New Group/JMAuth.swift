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

class JMAuth {
    private let mock: Bool
    let willFail: Bool
    let mockUser: LocalUser?
    let auth = Auth.auth()
    var currentUser: LocalUser? {
        if mock {
            return mockUser
        } else {
            guard let user = Auth.auth().currentUser else { return nil }
            return LocalUser(user: user)
        }
    }


    init() {
        mock = false
        willFail = false
        mockUser = nil
    }

    init(mock: Bool, willFail: Bool, mockUser: LocalUser?) {
        self.mock = mock
        self.willFail = willFail
        self.mockUser = mockUser
    }

    func createUser(withEmail email: String, password: String, completion: AuthDataResultCallback? = nil) {
        guard mock else {
            auth.createUser(withEmail: email, password: password, completion: completion)
            return
        }
        guard let block = completion else { return }
        if willFail {
            block(nil, ErrorMock())
        } else {
            block(nil, nil)
        }
    }

    func signIn(withEmail email: String, password: String, completion: ((Result<LocalUser, Error>) -> Void)? = nil) {
        guard mock else {
            auth.signIn(withEmail: email, password: password) { (data, error) in
                guard let completion = completion else { return }
                if let error = error {
                    completion(.failure(error))
                    return
                }
                if let data = data {
                    completion(.success(LocalUser(user: data.user)))
                }
            }
            return
        }
        guard let block = completion else { return }
        if willFail {
            block(.failure(ErrorMock()))
        } else {
            block(.success(LocalUser()))
        }
    }

    func signOut() throws {
        guard mock else {
            try auth.signOut()
            return
        }
        if willFail {
            throw ErrorMock()
        }
    }
}
