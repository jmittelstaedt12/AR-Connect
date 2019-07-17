//
//  MockFIRDatabase.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 7/17/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Firebase

protocol FIRDatabaseType {
    func reference(withPath path: String) -> DatabaseReferenceType
}
final class MockFIRDatabase: FIRDatabaseType {
    func reference(withPath path: String) -> DatabaseReferenceType {
        return MockDatabaseReference(childStrings: ["Users"], database: MockDatabase())
    }
}
