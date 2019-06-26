//
//  ARConnectTests.swift
//  ARConnectTests
//
//  Created by Jacob Mittelstaedt on 6/26/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import XCTest

class ARConnectTests: XCTestCase {

    func testHelloWorld() {
        var helloWorld: String?

        XCTAssertNil(helloWorld)

        helloWorld = "hello world"
        XCTAssertEqual(helloWorld, "hello world")
    }

}

