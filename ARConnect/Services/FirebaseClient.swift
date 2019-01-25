//
//  FirebaseClient.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/9/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import Firebase
import UIKit
import RxSwift

fileprivate struct FIRObservables {
    var usersObservable: Observable<[LocalUser]>?
    var requestingUserUidObservable: Observable<String>?
    var requestIsPendingObservable: Observable<Bool>?
    var amOnlineObservable: Observable<Bool>?
    var amInSessionObservable: Observable<Bool>?
}

fileprivate var observables = FIRObservables()

struct FirebaseClient {

    static let usersRef = Database.database().reference().child("Users")
    static var observedReferences = [DatabaseReference]()

    enum UserUnavailableError: LocalizedError {
        case isOffline
        case unavailable
        case amOffline
        public var errorDescription: String? {
            switch self {
            case .isOffline:
                return NSLocalizedString("User is offline", comment: "")
            case .unavailable:
                return NSLocalizedString("User is unavailable", comment: "")
            case .amOffline:
                return NSLocalizedString("You are offline", comment: "")
            }
        }
    }

    /// Request to authorize a new user and add them to database
    static func createNewUser(name: String, email: String, password: String, pngData: Data?, handler: @escaping (() -> Void)) throws {
        guard let png = pngData else {
            registerNewUser(name: name, email: email, password: password)
            return
        }
        let imageName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("\(imageName).png")
        storageRef.putData(png, metadata: nil) { (_, error) in
            if let err = error {
                print(err.localizedDescription)
                return
            }
            storageRef.downloadURL { (url, error) in
                if let err = error {
                    print(err.localizedDescription)
                    return
                }
                registerNewUser(name: name, email: email, password: password, imageUrl: url?.absoluteString, handler: { handler() })
            }
        }
    }

    static func registerNewUser(name: String, email: String, password: String, imageUrl: String? = nil, handler: (() -> Void)? = nil) {
        Auth.auth().createUser(withEmail: email, password: password) { (data, error) in
            if let err = error {
                print(err.localizedDescription)
                return
            }
            guard let uid = data?.user.uid else { return }
            let usersReference = FirebaseClient.usersRef.child(uid)
            let values = ["email": email,
                "name": name,
                "requestingUser": "",
                "connectedTo": "",
                "pendingRequest": false,
                "isConnected": false,
                "latitude": 0,
                "longitude": 0,
                "profileImageUrl": imageUrl ?? "",
                "isOnline": false] as [String: Any]
            usersReference.updateChildValues(values, withCompletionBlock: { (error, _) in
                        if let err = error {
                            print(err.localizedDescription)
                            return
                        }
                        if let handler = handler { handler() }
                })
        }
    }

    /// Request from view controller to log in to the database
    static func logInToDB(email: String, password: String, controller: UIViewController) {
        Auth.auth().signIn(withEmail: email, password: password) { (_, error) in
            if let err = error {
                controller.createAndDisplayAlert(withTitle: "Authorization error", body: err.localizedDescription)
                return
            }
            AppDelegate.shared.rootViewController.switchToMainScreen()
        }
    }

    /// Log out current user and return to login screen
    static func logoutOfDB() throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        for ref in observedReferences {
            ref.removeAllObservers()
        }
        do {
            try Auth.auth().signOut()
            observables = FIRObservables()
            usersRef.child(uid).updateChildValues(["connectedTo": "",
                "isOnline": false,
                "pendingRequest": false,
                "isConnected": false,
                "requestingUser": ""])
        } catch let logoutError {
            throw logoutError
        }
    }

    static func setOnDisconnectUpdates(forUid uid: String) {
        let userRef = usersRef.child(uid)
        userRef.child("connectedTo").onDisconnectSetValue("")
        userRef.child("isOnline").onDisconnectSetValue(false)
        userRef.child("pendingRequest").onDisconnectSetValue(false)
        userRef.child("isConnected").onDisconnectSetValue(false)
        userRef.child("requestingUser").onDisconnectSetValue("")
    }

    static func rxFirebaseSingleEvent(forRef ref: DatabaseReference, andEvent event: DataEventType) -> Observable<DataSnapshot> {
        return Observable.create { (observer) -> Disposable in
            ref.observeSingleEvent(of: event, with: { (snapshot) in
                observer.onNext(snapshot)
            }, withCancel: { (error) in
                    observer.onError(error)
                })
            return Disposables.create()
        }
    }

    static func rxFirebaseListener(forRef ref: DatabaseReference, andEvent event: DataEventType) -> Observable<DataSnapshot> {
        return Observable.create { (observer) -> Disposable in
            let handle = ref.observe(event, with: { (snapshot) in
                observer.onNext(snapshot)
            }, withCancel: { (error) in
                    observer.onError(error)
                })
            return Disposables.create {
                ref.removeObserver(withHandle: handle)
            }
        }
    }

    static func fetchObservableUser(forUid uid: String) -> Observable<LocalUser> {
        return rxFirebaseSingleEvent(forRef: usersRef.child(uid), andEvent: .value)
            .filter { $0.value is [String: AnyObject] }
            .map { snapshot in
                let dictionary = snapshot.value as! [String: AnyObject]
                let user = LocalUser()
                user.name = dictionary["name"] as? String
                user.email = dictionary["email"] as? String
                user.uid = uid
                return user
        }
    }

    /// Fetch all the users currently in the database as an observable
    static func fetchObservableUsers() -> Observable<[LocalUser]> {
        if let observable = observables.usersObservable { return observable }
        #warning("add timer to this observable")
        observables.usersObservable = rxFirebaseListener(forRef: usersRef, andEvent: .value)
        //            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
        .filter { $0.value is [String: AnyObject] }
            .map { snapshot in
                var dictionary = snapshot.value as! [String: AnyObject]
                if let uid = Auth.auth().currentUser?.uid {
                    dictionary.removeValue(forKey: uid)
                }
                let users = dictionary.values
                    .filter { $0 is [String: AnyObject] }
                    .map { $0 as! [String: AnyObject] }
                    .map { userDictionary -> LocalUser in
                        let user = LocalUser()
                        user.name = userDictionary["name"] as? String
                        user.email = userDictionary["email"] as? String
                        user.isOnline = userDictionary["isOnline"] as? Bool
                        if let urlString = userDictionary["profileImageUrl"] as? String, !urlString.isEmpty, let url = URL(string: urlString) { user.profileUrl = url }
                        return user
                }
                for (index, uid) in dictionary.keys.enumerated() {
                    users[index].uid = uid
                }
                return users
            }
            .share(replay: 1)
        return observables.usersObservable!
    }

    /// Create observable that fetches requesting user
    static func createRequestingUserObservable() -> Observable<LocalUser>? {
        let requestingUserObservable = createRequestingUserUidObservable()
        return requestingUserObservable?
            .flatMapLatest { fetchObservableUser(forUid: $0) }
            .share(replay: 1)
    }

    /// Create observable to monitor incoming request user uid's
    static func createRequestingUserUidObservable() -> Observable<String>? {
        if let observable = observables.requestingUserUidObservable { return observable }
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        observables.requestingUserUidObservable = rxFirebaseListener(forRef: usersRef.child(uid).child("requestingUser"), andEvent: .value)
            .filter { $0.value is String }
            .map { $0.value as! String }
            .filter { !$0.isEmpty }
            .share(replay: 1)
        return observables.requestingUserUidObservable
    }

    static func createNoRequestingUserObservable(forUid uid: String) -> Observable<Bool> {
        return rxFirebaseListener(forRef: usersRef.child(uid).child("requestingUser"), andEvent: .value)
            .filter { $0.value is String }
            .map { $0.value as! String }
            .map { $0.isEmpty }
            .filter { $0 }
            .share(replay: 1)
    }

    /// Create requesting user for uid observable
    static func createRequestIsPendingObservable(forUid uid: String) -> Observable<Bool> {
        if uid == Auth.auth().currentUser?.uid, let observable = observables.requestIsPendingObservable { return observable }
        let requestIsPendingObservable = rxFirebaseListener(forRef: usersRef.child(uid).child("pendingRequest"), andEvent: .value)
            .filter { $0.value is Bool }
            .map { $0.value as! Bool }
            .share(replay: 1)
        if uid == Auth.auth().currentUser?.uid { observables.requestIsPendingObservable = requestIsPendingObservable }
        return requestIsPendingObservable
    }

    /// Create single event observable for user online with uid
    static func createUserOnlineObservable(forUid uid: String) -> Observable<Bool> {
        return rxFirebaseSingleEvent(forRef: usersRef.child(uid).child("isOnline"), andEvent: .value)
            .filter { $0.value is Bool }
            .map { $0.value as! Bool }
    }

    /// Create obserable to monitor if you are currently online
    static func createAmOnlineObservable() -> Observable<Bool> {
        if let observable = observables.amOnlineObservable { return observable }
        observables.amOnlineObservable = rxFirebaseListener(forRef: Database.database().reference(withPath: ".info/connected"), andEvent: .value)
            .filter { $0.value is Bool }
            .map { $0.value as! Bool }
            .share(replay: 1)
        return observables.amOnlineObservable!
    }

    /// Create observable to check if user is available to connect
    static func createUserAvailableObservable(forUid uid: String) -> Observable<Bool> {
        let isOnlineObservable = createUserOnlineObservable(forUid: uid)
        let isInSessionObservable = rxFirebaseSingleEvent(forRef: usersRef.child(uid).child("isConnected"), andEvent: .value)
            .filter { $0.value is Bool }
            .map { $0.value as! Bool }

        let isPendingObservable = rxFirebaseSingleEvent(forRef: usersRef.child(uid).child("pendingRequest"), andEvent: .value)
            .filter { $0.value is Bool }
            .map { $0.value as! Bool }

        return Observable.combineLatest(isOnlineObservable, isInSessionObservable, isPendingObservable) {
            if !$0 { throw UserUnavailableError.isOffline }
            if $1 || $2 { throw UserUnavailableError.unavailable }
            return $0 && !$1 && !$2
        }
    }

    static func createCallUserObservable(forUid uid: String) -> Observable<Bool> {
        let isAvailableObservable = createUserAvailableObservable(forUid: uid)
        let amOnlineObservable = createAmOnlineObservable()
        return Observable.combineLatest(isAvailableObservable, amOnlineObservable) {
            if !$1 { throw UserUnavailableError.amOffline }
            return $0 && $1
        }.take(1)
    }

    static func willDisplayRequestingUserObservable() -> Observable<LocalUser>? {
        guard let currentUid = Auth.auth().currentUser?.uid else { return nil }
        let requestingUidObservable = createRequestingUserUidObservable() // get requesting uid
        let isOnlineObservable = requestingUidObservable?.flatMap { createUserOnlineObservable(forUid: $0) } // requesting user is available
        let pendingObservable = createRequestIsPendingObservable(forUid: currentUid) // you are not awaiting a response from someone else
        let amOnlineObservable = createAmOnlineObservable() // you are online

        return Observable.combineLatest(isOnlineObservable!, pendingObservable, amOnlineObservable) { isOnline, amPending, amOnline -> Bool in
            return isOnline && !amPending && amOnline && Auth.auth().currentUser != nil
        }.filter { $0 }
            .flatMapLatest { _ -> Observable<LocalUser> in
                return createRequestingUserObservable()!
            }
            .share(replay: 1)
    }

    static func createCallDroppedObservable(forUid uid: String) -> Observable<Bool>? {
        let requestIsPendingObservable = createRequestIsPendingObservable(forUid: uid)
        let isInSessionObservable = createIsInSessionObservable(forUid: uid)
        return requestIsPendingObservable
            .filter { !$0 }
            .flatMapLatest { _ in return isInSessionObservable }
            .filter { !$0 }
    }

    static func createCalledUserResponseObservable(forUid uid: String) -> Observable<Bool>? {
        guard let currentUid = Auth.auth().currentUser?.uid else { return nil }
        return createNoRequestingUserObservable(forUid: uid)
            .flatMapLatest { _ in return createIsInSessionObservable(forUid: currentUid) }
            .take(1)
            .share(replay: 1)
    }

    static func createIsInSessionObservable(forUid uid: String) -> Observable<Bool> {
        if uid == Auth.auth().currentUser?.uid, let observable = observables.amInSessionObservable { return observable }
        let isInSessionObservable = rxFirebaseListener(forRef: usersRef.child(uid).child("isConnected"), andEvent: .value)
            .filter { $0.value is Bool }
            .map { $0.value as! Bool }
        if uid == Auth.auth().currentUser?.uid { observables.amInSessionObservable = isInSessionObservable }
        return isInSessionObservable
    }

    static func createEndSessionObservable(forUid uid: String) -> Observable<Bool>? {
        guard let currentUid = Auth.auth().currentUser?.uid else { return nil }
        let amInSessionObservable = createIsInSessionObservable(forUid: currentUid)
        let isInSessionObservable = createIsInSessionObservable(forUid: uid)
        return Observable.combineLatest(amInSessionObservable, isInSessionObservable) { return !$0 || !$1 }
            .filter { $0 }
            .take(1)
    }

    static func fetchCoordinates(uid: String, handler: @escaping((Double?, Double?) -> Void)) {
        let userRef = usersRef.child(uid)
        userRef.observeSingleEvent(of: .value) { (snapshot) in
            if let userDictionary = snapshot.value as? [String: Any] {
                let latitude = userDictionary["latitude"] as? Double
                let longitude = userDictionary["longitude"] as? Double
                handler(latitude, longitude)
            }
        }
    }

}
