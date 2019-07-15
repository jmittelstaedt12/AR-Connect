//
//  DatabaseReferenceMock.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/27/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Foundation
import Firebase
import RxSwift
import RxCocoa

class DatabaseeReferenceMock: DatabaseReference {

    static var databaseObservable: BehaviorRelay<[String: Any]>!

    class func initializeDatabase(mockDatabaseDictionary: [String: Any]) {
        databaseObservable = BehaviorRelay<[String: Any]>(value: mockDatabaseDictionary)
    }
    var pathStrings: [String] {
        didSet {
            var dictionaryValue: [String: Any]? = DatabaseeReferenceMock.databaseObservable.value
            for index in 0..<pathStrings.count-1 {
                dictionaryValue = dictionaryValue?[pathStrings[index]] as? [String: Any]
            }
            let result = dictionaryValue?[pathStrings.last!] as Any
            valueObservable.accept(result)
        }
    }
    var willFail = false
    let disposeBag = DisposeBag()
    let valueObservable: BehaviorRelay<Any?>

    init(pointsTo: [String]) {
        pathStrings = pointsTo
        guard !pathStrings.isEmpty else {
            valueObservable = BehaviorRelay<Any?>(value: DatabaseeReferenceMock.databaseObservable.value)
            super.init()
            return
        }
        valueObservable = BehaviorRelay<Any?>(value: (DatabaseeReferenceMock.databaseObservable.value as NSDictionary).value(forKeyPath: self.pathStrings.joined(separator: ".")))
        super.init()
        DatabaseeReferenceMock.databaseObservable
            .map { ($0 as NSDictionary).value(forKeyPath: self.pathStrings.joined(separator: ".")) }
            .subscribe(onNext: { [weak self] val in
                self?.valueObservable.accept(val)
            })
            .disposed(by: disposeBag)
    }

    override func child(_ pathString: String) -> DatabaseReference {
        guard let value = valueObservable.value as? [String: Any], value[pathString] != nil else {
            fatalError("non existant child")
        }
        return DatabaseeReferenceMock(pointsTo: pathStrings + [pathString])
    }

    override func observeSingleEvent(of eventType: DataEventType, with block: @escaping (DataSnapshot) -> Void, withCancel cancelBlock: ((Error) -> Void)? = nil) {
        if willFail {
            if let block = cancelBlock {
                block(ErrorMock())
            }
        } else {
            let snapshot = DataSnapshotMock(value: valueObservable.value)
            block(snapshot)
        }
    }

    override func observe(_ eventType: DataEventType, with block: @escaping (DataSnapshot) -> Void, withCancel cancelBlock: ((Error) -> Void)? = nil) -> UInt {
        if willFail {
            if let block = cancelBlock {
                block(ErrorMock())
            }
        } else {
            valueObservable
                .subscribe(onNext: { value in
                    guard let value = value else { return }
                    let snapshot = DataSnapshotMock(value: value)
                    block(snapshot)
                })
                .disposed(by: disposeBag)
        }
        return 0
    }

    override func onDisconnectUpdateChildValues(_ values: [AnyHashable: Any]) {
        guard !willFail, let values = values as? [String: Any] else {
            return
        }
        let dict = NSMutableDictionary(dictionary: DatabaseeReferenceMock.databaseObservable.value)
        dict.setValue(values, forKeyPath: self.pathStrings.joined(separator: "."))
        DatabaseeReferenceMock.databaseObservable.accept(dict as! [String: Any])
    }

    override func updateChildValues(_ values: [AnyHashable: Any]) {
        guard !willFail, let values = values as? [String: Any] else {
            return
        }
        var dict = DatabaseeReferenceMock.databaseObservable.value
        for value in values {
            dict[keyPath: KeyPath((self.pathStrings + [value.key]).joined(separator: "."))] = value.value as Any
        }
        print(dict)
        DatabaseeReferenceMock.databaseObservable.accept(dict)
    }

    override func setValue(_ value: Any?, withCompletionBlock block: @escaping (Error?, DatabaseReference) -> Void) {
        if willFail {
            block(ErrorMock(), self)
            return
        }
        let keyPathString = pathStrings.reduce("") { $0 + "." + $1}
        let mutableDictionary = DatabaseeReferenceMock.databaseObservable.value as! NSMutableDictionary
        mutableDictionary.setValue(value, forKeyPath: keyPathString)
        DatabaseeReferenceMock.databaseObservable.accept(mutableDictionary as! [String: Any])
        block(nil, self)
    }
}

//struct FirebaseUserMock {
//    let connectedTo: String?
//    let email: String?
//    let isConnected: Bool?
//    let isOnline: Bool?
//    let isPending: Bool?
//    let isPending: Double?
//    let longitude: Double?
//    let name: String?
//    let pendingRequest: Bool?
//    let profileImageUrl: String?
//    let requestingUser: [String: Any]?
//}
