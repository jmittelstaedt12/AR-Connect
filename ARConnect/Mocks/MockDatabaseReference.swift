//
//  DatabaseReferenceMock.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/27/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

// swiftlint:disable colon

import Foundation
import Firebase
import RxSwift
import RxCocoa

protocol DatabaseQueryType {
    func observeSingleEvent(of eventType: DataEventType, with block: @escaping (DataSnapshot) -> Void, withCancel cancelBlock: ((Error) -> Void)?)
    func observe(_ eventType: DataEventType, with block: @escaping (DataSnapshot) -> Void, withCancel cancelBlock: ((Error) -> Void)?) -> UInt
    func queryOrdered(byChild key: String) -> DatabaseQuery
}

protocol DatabaseReferenceType: DatabaseQueryType {
    func child(at pathString: String) -> DatabaseReferenceType
    func onDisconnectUpdateChildValues(_ values: [AnyHashable: Any])
    func updateChildValues(_ values: [AnyHashable: Any])
    func updateChildValues(_ values: [AnyHashable : Any], withCompletionBlock block: @escaping (Error?, DatabaseReference) -> Void)
    func setValue(_ value: Any?, withCompletionBlock block: @escaping (Error?, DatabaseReference) -> Void)
}

class MockDatabaseReference: DatabaseReferenceType {

    var databaseInstance: MockDatabase
    var currentValue: Any
    let key: String
    let fullPath: String
    let childStrings: [String]
    var snapshot: DataSnapshot
    let snapshotObservable: BehaviorRelay<DataSnapshot>
    let disposeBag = DisposeBag()

    enum MockResponse {
        case pending, passed, failed
    }
    private(set) var mockResponse: MockResponse = .pending
    var willSucceed = true

    init(childStrings: [String] = [String](), database: MockDatabase) {
        self.databaseInstance = database
        self.childStrings = childStrings
        self.key = childStrings.last!
        self.fullPath = childStrings.joined(separator: ".")
        self.currentValue = databaseInstance.database[keyPath: KeyPath(fullPath)]
        self.snapshot = MockDataSnapshot(value: currentValue)
        self.snapshotObservable = BehaviorRelay<DataSnapshot>(value: snapshot)

        databaseInstance.rx.observe([String : [String : [String : Any]]].self, "database")
            .subscribe(onNext: { [weak self] database in
                guard let self = self, let database = database else { return }
                self.currentValue = database[keyPath: KeyPath(self.fullPath)]
                self.snapshot = MockDataSnapshot(value: self.currentValue)
                self.snapshotObservable.accept(self.snapshot)
            })
            .disposed(by: disposeBag)
    }

    func child(at pathString: String) -> DatabaseReferenceType {
        return MockDatabaseReference(childStrings: childStrings + [pathString], database: databaseInstance)
    }

    func observeSingleEvent(of eventType: DataEventType, with block: @escaping (DataSnapshot) -> Void, withCancel cancelBlock: ((Error) -> Void)? = nil) {
        switch willSucceed {
        case true:
            block(snapshot)
        case false:
            if let cancelBlock = cancelBlock { cancelBlock(MockError()) }
        }
    }

    func observe(_ eventType: DataEventType, with block: @escaping (DataSnapshot) -> Void, withCancel cancelBlock: ((Error) -> Void)? = nil) -> UInt {
        switch willSucceed {
        case true:
            snapshotObservable
                .subscribe(onNext: { snapshot in
                     block(snapshot)
                }, onDisposed: {
                    print("disposed")
                })
                .disposed(by: disposeBag)
        case false:
            if let cancelBlock = cancelBlock { cancelBlock(MockError()) }
        }
        return 0
    }

    func onDisconnectUpdateChildValues(_ values: [AnyHashable : Any]) {
        // do nothing
    }

    func updateChildValues(_ values: [AnyHashable: Any]) {
        // do nothing
    }

    func updateChildValues(_ values: [AnyHashable : Any], withCompletionBlock block: @escaping (Error?, DatabaseReference) -> Void) {
        // do nothing
    }

    func setValue(_ value: Any?, withCompletionBlock block: @escaping (Error?, DatabaseReference) -> Void) {
        // do nothing
    }

    func queryOrdered(byChild key: String) -> DatabaseQuery {
        // do nothing
        return DatabaseQuery()
    }
}
// swiftlint:enable colon
