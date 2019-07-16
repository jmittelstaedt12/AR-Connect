//
//  DataSnapshotMock.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/27/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Foundation
import Firebase

class MockDataSnapshot: DataSnapshot {
    private var myValue: Any?

    override var value: Any? {
        get {
            return myValue
        }
        set {
            myValue = newValue
        }
    }

    init(value: Any) {
        super.init()
        self.value = value
    }
}
