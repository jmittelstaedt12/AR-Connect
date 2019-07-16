//
//  MainViewModelTests.swift
//  ARConnectTests
//
//  Created by Jacob Mittelstaedt on 7/16/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

// swiftlint:disable function_body_length

import Quick
import Nimble
import RxSwift
import RxBlocking
import RxTest

@testable import ARConnect

final class MainViewModelTests: QuickSpec {

    override func spec() {
        var client: MockFirebaseClient!
        var scheduler: TestScheduler!
        var disposeBag: DisposeBag!
        var subject: MainViewModel!

        beforeEach {
            scheduler = TestScheduler(initialClock: 0)
            disposeBag = DisposeBag()

            client = MockFirebaseClient()
            subject = MainViewModel(firebaseClient: client)
        }

        describe("user authentication status") {
            context("user is authenticated") {
                it("notifies authenticated observable") {
                }
            }
        }
    }
}

// swiftlint:enable function_body_length
