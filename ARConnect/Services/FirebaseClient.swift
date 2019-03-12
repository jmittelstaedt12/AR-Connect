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
    static func createNewUser(user: RegisterUser, handler: @escaping ((Error?) -> Void)) {
        guard let png = user.pngData else {
            registerNewUser(user: user, handler: handler)
            return
        }
        let imageName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("\(imageName).png")
        storageRef.putData(png, metadata: nil) { (_, error) in
            if let err = error {
                handler(err)
                return
            }
            storageRef.downloadURL { (url, error) in
                if let err = error {
                    handler(err)
                    return
                }
                registerNewUser(user: user, imageUrl: url?.absoluteString, handler: handler)
            }
        }
    }

    static func registerNewUser(user: RegisterUser, imageUrl: String? = nil, handler: @escaping ((Error?) -> Void)) {
        Auth.auth().createUser(withEmail: user.email, password: user.password) { (data, error) in
            if let err = error {
                handler(err)
                return
            }
            guard let uid = data?.user.uid else { return }

            var postError: Error?
            let userReference = FirebaseClient.usersRef.child(uid)
            let requestingUserReference = userReference.child("requestingUser")

            let values = ["email": user.email,
                          "name": "\(user.firstName!) \(user.lastName!)",
                          "connectedTo": "",
                          "pendingRequest": false,
                          "isConnected": false,
                          "latitude": 0,
                          "longitude": 0,
                          "profileImageUrl": imageUrl ?? "",
                          "isOnline": false] as [String: Any]

            let requestingUserValues = ["uid": "",
                                        "latitude": 0,
                                        "longitude": 0] as [String: Any]

            let group = DispatchGroup()
            group.enter()
            userReference.setValue(values, withCompletionBlock: { (error, _) in
                postError = error
                group.leave()
            })

            group.enter()
            requestingUserReference.setValue(requestingUserValues, withCompletionBlock: { (error, _) in
                postError = error
                group.leave()
            })

            group.notify(queue: .main) {
                handler(postError)
            }
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
            usersRef.child(uid).updateChildValues([
                "connectedTo": "",
                "isOnline": false,
                "pendingRequest": false,
                "isConnected": false
                ])
            usersRef.child(uid).child("requestingUser").updateChildValues([
                "uid": "",
                "latitude": 0,
                "longitude": 0
                ])
        } catch let logoutError {
            throw logoutError
        }
    }

//    static func sendConnectRequestToUser(withUid uid: String, atCoordinateTuple coordinate: (latitude: Double, longitude: Double)) -> Observable<String> {
//        #warning("combine with createCanCallObservable")
//        return Observable.create({ (observer) -> Disposable in
//            FirebaseClient.usersRef.child(Auth.auth().currentUser!.uid).updateChildValues(["pendingRequest": true])
//            let requestingUserRef = usersRef.child(uid).child("requestingUser")
//            requestingUserRef.updateChildValues(["uid": uid,
//                                                 "latitude": coordinate.latitude,
//                                                 "longitude": coordinate.longitude
//            ]) { (error, _) in
//                if let error = error {
//                    observer.onError(error)
//                } else {
//                    observer.onNext(uid)
//                }
//                observer.onCompleted()
//            }
//            return Disposables.create()
//        })
//    }

    static func setOnDisconnectUpdates(forUid uid: String) {
        let userRef = usersRef.child(uid)
        userRef.child("connectedTo").onDisconnectSetValue("")
        userRef.child("isOnline").onDisconnectSetValue(false)
        userRef.child("pendingRequest").onDisconnectSetValue(false)
        userRef.child("isConnected").onDisconnectSetValue(false)
        userRef.child("requestingUser").child("uid").onDisconnectSetValue("")
        userRef.child("requestingUser").child("latitude").onDisconnectSetValue(0)
        userRef.child("requestingUser").child("longitude").onDisconnectSetValue(0)
    }

    static func rxFirebaseSingleEvent(forRef ref: DatabaseQuery, andEvent event: DataEventType) -> Observable<DataSnapshot> {
        return Observable.create { (observer) -> Disposable in
            ref.observeSingleEvent(of: event, with: { (snapshot) in
                observer.onNext(snapshot)
                observer.onCompleted()
            }, withCancel: { (error) in
                    observer.onError(error)
                })
            return Disposables.create()
        }
    }

    static func rxFirebaseListener(forRef ref: DatabaseQuery, andEvent event: DataEventType) -> Observable<DataSnapshot> {
        return Observable.create { (observer) -> Disposable in
            ref.observe(event, with: { (snapshot) in
                observer.onNext(snapshot)
            }, withCancel: { (error) in
                observer.onError(error)
            })
            return Disposables.create()
        }
    }

    static func fetchObservableUser(forUid uid: String) -> Observable<LocalUser> {
        return rxFirebaseSingleEvent(forRef: usersRef.child(uid), andEvent: .value)
            .filter { $0.value is [String: AnyObject] }
            .map { snapshot in
                let dictionary = snapshot.value as! [String: AnyObject]
                var user = LocalUser()
                user.name = dictionary["name"] as? String
                user.email = dictionary["email"] as? String
                user.uid = uid
                return user
        }
    }

    enum FetchUsersObservableType {
        case singleEvent
        case continuous
    }

    /// Fetch all the users currently in the database as an observable
    static func fetchObservableUsers(withObservableType type: FetchUsersObservableType, queryReference: DatabaseQuery? = nil) -> Observable<[LocalUser]> {
        if let observable = observables.usersObservable, type == .continuous { return observable }
        observables.usersObservable = rxFirebaseListener(forRef: queryReference ?? usersRef, andEvent: .value)
        .filter { $0.value is [String: AnyObject] }
            .map { snapshot in
                var dictionary = snapshot.value as! [String: AnyObject]
                if let uid = Auth.auth().currentUser?.uid {
                    dictionary.removeValue(forKey: uid)
                }
                var users = dictionary.values
                    .filter { $0 is [String: AnyObject] }
                    .map { $0 as! [String: AnyObject] }
                    .map { userDictionary -> LocalUser in
                        var user = LocalUser()
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
        switch type {
        case .continuous:
            return observables.usersObservable!
        case .singleEvent:
            return observables.usersObservable!.take(1)
        }
    }

    static func fetchRequestingUser(uid: String) -> Observable<(LocalUser, [String: AnyObject])> {
        return Observable.create { (observer) -> Disposable in
            let currentUserRef = usersRef.child(Auth.auth().currentUser!.uid)
            let requestingUserRef = usersRef.child(uid)

            let group = DispatchGroup()
            group.enter()
            var requestingUserDictionary: [String: AnyObject] = [:]
            currentUserRef.child("requestingUser").observeSingleEvent(of: .value, with: { snapshot in
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    requestingUserDictionary = dictionary
                }
                group.leave()
            }, withCancel: { error in
                observer.onError(error)
                group.leave()
            })

            group.enter()
            var requestingUser = LocalUser()
            requestingUserRef.observeSingleEvent(of: .value, with: { snapshot in
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    requestingUser.uid = uid
                    requestingUser.name = dictionary["name"] as? String
                    requestingUser.email = dictionary["email"] as? String
                    requestingUser.profileUrl = (dictionary["email"] is String) ? URL(fileURLWithPath: dictionary["email"] as! String) : nil
                }
                group.leave()
            }, withCancel: { error in
                observer.onError(error)
                group.leave()
            })

            group.notify(queue: .main) {
                observer.onNext((requestingUser, requestingUserDictionary))
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

//    /// Create observable that fetches requesting user
//    static func createRequestingUserObservable() -> Observable<LocalUser>? {
//        let requestingUserObservable = createRequestingUserUidObservable()
//        return requestingUserObservable?
//            .flatMapLatest { fetchObservableUser(forUid: $0) }
//            .share(replay: 1)
//    }

    /// Create observable to monitor incoming request user uid's
    static func createRequestingUserUidObservable() -> Observable<String>? {
        if let observable = observables.requestingUserUidObservable { return observable }
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        observables.requestingUserUidObservable = rxFirebaseListener(forRef: usersRef.child(uid).child("requestingUser").child("uid"), andEvent: .value)
            .filter { $0.value is String }
            .map { $0.value as! String }
            .filter { !$0.isEmpty }
            .share(replay: 1)
        return observables.requestingUserUidObservable
    }

    static func createNoRequestingUserObservable(forUid uid: String) -> Observable<Bool> {
        return rxFirebaseListener(forRef: usersRef.child(uid).child("requestingUser").child("uid"), andEvent: .value)
            .filter { $0.value is String }
            .map { $0.value as! String }
            .map { $0.isEmpty }
            .filter { $0 }
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

    static func createCallUserObservable(forUid uid: String, atCoordinateTuple coordinate: (latitude: Double, longitude: Double)) -> Observable<Bool> {
        let currentUid = Auth.auth().currentUser!.uid
        let isAvailableObservable = createUserAvailableObservable(forUid: uid)
        let amOnlineObservable = createAmOnlineObservable()
        return Observable.combineLatest(isAvailableObservable, amOnlineObservable) {
            if !$0 { throw UserUnavailableError.unavailable }
            if !$1 { throw UserUnavailableError.amOffline }
            return $0 && $1
            }
            .filter { $0 }
            .flatMap { _ in return Observable.create({ (observer) -> Disposable in
                    let requestingUserRef = usersRef.child(uid).child("requestingUser")
                    requestingUserRef.updateChildValues(["uid": currentUid,
                                                         "latitude": coordinate.latitude,
                                                         "longitude": coordinate.longitude]
                    ) { (error, _) in
                        if let error = error {
                            observer.onError(error)
                        } else {
                            observer.onNext(true)
                        }
                        observer.onCompleted()
                    }
                    return Disposables.create()
                })
            }.take(1)
    }

    static func willDisplayRequestingUserObservable() -> Observable<(LocalUser, [String: AnyObject])>? {
        guard let currentUid = Auth.auth().currentUser?.uid else { return nil }
        let requestingUidObservable = createRequestingUserUidObservable() // get requesting uid
        let isOnlineObservable = requestingUidObservable?.flatMap { createUserOnlineObservable(forUid: $0) } // requesting user is available
        let pendingObservable = createRequestIsPendingObservable(forUid: currentUid) // you are not awaiting a response from someone else
        let amOnlineObservable = createAmOnlineObservable() // you are online

        return Observable.combineLatest(isOnlineObservable!, pendingObservable, amOnlineObservable) { isOnline, amPending, amOnline -> Bool in
            return isOnline && !amPending && amOnline && Auth.auth().currentUser != nil
        }
            .filter { $0 }
            .flatMapLatest { _ -> Observable<String> in
                return createRequestingUserUidObservable()!
            }
            .flatMapLatest { uid -> Observable<(LocalUser, [String: AnyObject])> in
                return fetchRequestingUser(uid: uid)
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
