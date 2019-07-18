//
//  Firebase.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/27/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Foundation
import Firebase

struct Firebase {
    let auth: AuthType
    let usersRef: DatabaseReferenceType

    enum Functionality {
        case network, mock
    }

//    init(functionality: Functionality, auth: AuthType? = nil, usersRef: DatabaseReferenceType? = nil) {
    init(functionality: Functionality) {
        switch functionality {
        case .network:
            self.auth = Auth.auth()
            self.usersRef = Database.database().reference().child(at: "Users")
        case .mock:
            self.auth = MockAuth()
            self.usersRef = MockDatabaseReference(childStrings: ["Users"], database: MockDatabase())
        }
    }
}

extension Auth: AuthType {

    var user: LocalUser? {
        get {
        if let user = Auth.auth().currentUser {
            return LocalUser(user: user)
        } else {
            return nil
            }
        }
        set {}
    }

    func createUser(withEmail email: String, password: String, completion: ((Result<LocalUser, Error>) -> ())?) {
        createUser(withEmail: email, password: password) { (result, error) in
            if let error = error {
                completion?(.failure(error))
            } else if let result = result {
                completion?(.success(LocalUser(user: result.user)))
            }
        }
    }

    func signIn(withEmail email: String, password: String, completion: ((Result<LocalUser, Error>) -> ())?) {
        signIn(withEmail: email, password: password, completion: { (result, error) in
            if let error = error {
                completion?(.failure(error))
            } else if let result = result {
                completion?(.success(LocalUser(user: result.user)))
            }
        })
    }
}

extension DatabaseReference: DatabaseReferenceType {
    func child(at pathString: String) -> DatabaseReferenceType {
        let ref: DatabaseReference = self.child(pathString)
        return ref as DatabaseReferenceType
    }
}

extension DatabaseQuery: DatabaseQueryType {}
