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
    static func createNewUser(name: String, email: String, password: String, pngData: Data?, handler: @escaping (() -> ())) throws {
        guard let png = pngData else {
            registerNewUser(name: name, email: email, password: password)
            return
        }
        let imageName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("\(imageName).png")
        storageRef.putData(png, metadata: nil) { (metadata, error) in
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
    
    static func registerNewUser(name: String, email: String, password: String, imageUrl: String? = nil, handler: (() -> ())? = nil) {
        Auth.auth().createUser(withEmail: email, password: password) { (data, error) in
            if let err = error {
                print(err.localizedDescription)
                return
            }
            guard let uid = data?.user.uid else { return }
            let usersReference = FirebaseClient.usersRef.child(uid)
            let values = ["email" : email,
                          "name" : name,
                          "requestingUser" : "",
                          "connectedTo" : "",
                          "pendingRequest" : false,
                          "latitude" : 0,
                          "longitude" : 0,
                          "profileImageUrl" : imageUrl ?? "",
                          "isOnline" : false] as [String : Any]
            usersReference.updateChildValues(values, withCompletionBlock:
                { (error, ref) in
                    if let err = error {
                        print(err.localizedDescription)
                        return
                    }
                    if let handler = handler { handler() }
            })
        }
    }
    
    /// Request from view controller to log in to the database
    static func logInToDB(email: String,password: String,controller: UIViewController) {
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
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
            usersRef.child(uid).updateChildValues(["connectedTo" : "",
                                                   "isOnline" : false,
                                                   "pendingRequest" : false,
                                                   "requestingUser" : ""])
        } catch let logoutError {
            throw logoutError
        }
    }
    
    static func setOnDisconnectUpdates(forUid uid: String) {
        let userRef = usersRef.child(uid)
        userRef.child("connectedTo").onDisconnectSetValue("")
        userRef.child("isOnline").onDisconnectSetValue(false)
        userRef.child("pendingRequest").onDisconnectSetValue(false)
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
            .filter{ $0.value is [String: AnyObject] }
            .map{ snapshot in
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
        observables.usersObservable = rxFirebaseListener(forRef: usersRef, andEvent: .value)
            .filter { $0.value is [String: AnyObject] }
            .map { snapshot in
                let dictionary = snapshot.value as! [String: AnyObject]
                let users = dictionary.values
                    .filter { $0 is [String: AnyObject] }
                    .map { $0 as! [String: AnyObject] }
                    .map { userDictionary -> LocalUser in
                        let user = LocalUser()
                        user.name = userDictionary["name"] as? String
                        user.email = userDictionary["email"] as? String
                        if let urlString = userDictionary["profileImageUrl"] as? String, !urlString.isEmpty, let url = URL(string: urlString) { user.profileUrl = url }
                        return user
                    }
                for (i,k) in dictionary.keys.enumerated(){
                    users[i].uid = k
                }
                return users
            }
            .share(replay: 1)
        return observables.usersObservable!
    }
    
    /// Create observable that fetches requesting user
    static func createRequestingUserObservable() -> Observable<LocalUser>? {
        let requestingUserObservable = observables.requestingUserUidObservable ?? createRequestingUserUidObservable()
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
    
    static func createRequestingUserUidObservable(forUid uid: String) -> Observable<Bool> {
        return rxFirebaseListener(forRef: usersRef.child(uid).child("requestingUser"), andEvent: .value)
            .filter { $0.value is String }
            .map { $0.value as! String }
            .map { $0.isEmpty }
            .filter { $0 }
            .share(replay: 1)
    }
    
//    /// Create observable from current pending status
//    static func createRequestIsPendingObservable() -> Observable<Bool>? {
//        if let observable = observables.requestIsPendingObservable { return observable }
//        guard let uid = Auth.auth().currentUser?.uid else { return nil }
//        observables.requestIsPendingObservable = rxFirebaseListener(forRef: usersRef.child(uid).child("pendingRequest"), andEvent: .value)
//            .filter { $0.value is Bool }
//            .map { $0.value as! Bool }
//        return observables.requestIsPendingObservable
//    }
    
    /// Create requesting user for uid observable
    static func createRequestIsPendingObservable(forUid uid: String) -> Observable<Bool> {
        if  uid == Auth.auth().currentUser?.uid, let observable = observables.requestIsPendingObservable { return observable }
        let requestIsPendingObservable = rxFirebaseListener(forRef: usersRef.child(uid).child("pendingRequest"), andEvent: .value)
            .filter { $0.value is Bool }
            .map { $0.value as! Bool }
            .share(replay: 1)
        if  uid == Auth.auth().currentUser?.uid { observables.requestIsPendingObservable = requestIsPendingObservable }
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
        let notInSessionObservable = rxFirebaseSingleEvent(forRef: usersRef.child(uid).child("connectedTo"), andEvent: .value)
            .filter { $0.value is String }
            .map {$0.value as! String }
            .map { $0.isEmpty }
        
        let isPendingObservable = rxFirebaseSingleEvent(forRef: usersRef.child(uid).child("pendingRequest"), andEvent: .value)
            .filter { $0.value is Bool }
            .map { $0.value as! Bool }
        
        return Observable.combineLatest(isOnlineObservable, notInSessionObservable, isPendingObservable) {
            if !$0 { throw UserUnavailableError.isOffline }
            if !$1 || $2 { throw UserUnavailableError.unavailable }
            return $0 && $1 && !$2
        }
    }
    
    static func createCallUserObservable(forUid uid: String) -> Observable<Bool> {
        let isAvailableObservable = createUserAvailableObservable(forUid: uid)
        let amOnlineObservable  = createAmOnlineObservable()
        return Observable.combineLatest(isAvailableObservable, amOnlineObservable) {
            if !$1 { throw UserUnavailableError.amOffline }
            return $0 && $1
        }
    }
    
    
    
    static func willDisplayRequestingUserObservable() -> Observable<LocalUser>? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        let requestingUidObservable = observables.requestingUserUidObservable ?? createRequestingUserUidObservable() // get requesting uid
        let isOnlineObservable = requestingUidObservable?.flatMap { createUserOnlineObservable(forUid: $0) }        // requesting user is available
        let pendingObservable = observables.requestIsPendingObservable ?? createRequestIsPendingObservable(forUid: uid) // you are not awaiting a response from someone else
        let amOnlineObservable = observables.amOnlineObservable ?? createAmOnlineObservable()                        // you are online
        
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
        let isConnectedObservable = rxFirebaseSingleEvent(forRef: usersRef.child(uid).child("connectedTo"), andEvent: .value)
            .filter { $0.value is String }
            .map { $0.value as! String }
            .map { $0.isEmpty }
        return requestIsPendingObservable
            .filter { !$0 }
            .flatMapLatest { _ in return isConnectedObservable }
            .filter { $0 }
//        return Observable.combineLatest(requestIsPendingObservable, isConnectedObservable, resultSelector: { return !$0 && $1 })
//            .filter { $0 }
    }
    
    static func createCalledUserResponseObservable(forUid uid: String) -> Observable<Bool>? {
        guard let currentUid = Auth.auth().currentUser?.uid else { return nil }
        let isConnectedObservable = rxFirebaseListener(forRef: usersRef.child(uid).child("connectedTo"), andEvent: .value)
            .filter { $0.value is String }
            .map { $0.value as! String }
            .map { $0.isEmpty }
            .map { !$0 }
        return createRequestingUserUidObservable(forUid: uid)
//            .flatMapLatest { _ in return createRequestIsPendingObservable(forUid: currentUid) }
//            .filter { $0 }
            .flatMapLatest { _ in return isConnectedObservable }
            .share(replay: 1)
    }
    
//    /// Check for connection initialized
//    static func observeConnection(handler: @escaping((String) -> (Void))) {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//        let connectedToRef = usersRef.child(uid).child("connectedTo")
//        connectedToRef.observe(.value) { (snapshot) in
//            if let connectedTo = snapshot.value as? String {
//                if !connectedTo.isEmpty {
//                    handler(connectedTo)
//                }
//            }
//        }
//        observedReferences.append(connectedToRef)
//    }
    
    static func fetchCoordinates(uid: String, handler: @escaping((Double?,Double?) -> (Void))) {
        let userRef = usersRef.child(uid)
        userRef.observeSingleEvent(of: .value) { (snapshot) in
            if let userDictionary = snapshot.value as? [String : Any] {
                let latitude = userDictionary["latitude"] as? Double
                let longitude = userDictionary["longitude"] as? Double
                handler(latitude,longitude)
            }
        }
    }
    
//    static func observePending(handler: @escaping (() -> Void)) {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//        let userRef = usersRef.child(uid).child("pendingRequest")
//        userRef.observe(.value) { (snapshot) in
//            if let isPending = snapshot.value as? Bool {
//                if !isPending {
//                    handler()
//                    userRef.child("pendingRequest").removeAllObservers()
//                }
//            }
//        }
//        observedReferences.append(userRef)
//    }
}
