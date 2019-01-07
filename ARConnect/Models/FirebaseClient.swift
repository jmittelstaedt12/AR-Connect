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
    var requestingUserObservable: Observable<String>?
    var pendingRequestObservable: Observable<Bool>?
    var amOnlineObservable: Observable<Bool>?
}

fileprivate var observables = FIRObservables()

struct FirebaseClient {
    
    static let usersRef = Database.database().reference().child("Users")
    static var observedReferences = [DatabaseReference]()
    
    
    /// Request to authorize a new user and add them to database
    static func createNewUser(name: String, email: String,password: String, controller: UIViewController) {
        Auth.auth().createUser(withEmail: email, password: password) { (data, error) in
            if let err = error {
                let alert = UIAlertController(title: "Authorization error", message: err.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                controller.present(alert, animated: true, completion: nil)
                return
            }
            guard let uid = data?.user.uid else{
                return
            }
            let usersReference = usersRef.child(uid)
            let values = ["email" : email,
                          "name" : name,
                          "requestingUser" : "",
                          "connectedTo" : "",
                          "pendingRequest" : false,
                          "latitude" : 0,
                          "longitude" : 0,
                          "isOnline" : false] as [String : Any]
            usersReference.updateChildValues(values, withCompletionBlock:
            { (error, ref) in
                if let err = error {
                    let alert = UIAlertController(title: "Authorization error", message: err.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                    controller.present(alert, animated: true, completion: nil)
                    return
                }
                controller.dismiss(animated: true, completion: nil)
                AppDelegate.shared.rootViewController.switchToMainScreen()
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
    static func logoutOfDB(controller: UIViewController) -> Bool {
        for ref in observedReferences {
            ref.removeAllObservers()
        }
        do{
            try Auth.auth().signOut()
        }catch let logoutError {
            print(logoutError)
            controller.createAndDisplayAlert(withTitle: "Log out error", body: logoutError.localizedDescription)
            return false
        }
        return true
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
    
    static func fetchObservableUser(withUid uid: String) -> Observable<LocalUser> {
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
                        return user
                }
                for (i,k) in dictionary.keys.enumerated(){
                    users[i].uid = k
                }
                return users
            }
            .share()
        return observables.usersObservable!
    }
    
    static func displayRequestingUserObservable() -> Observable<LocalUser> {
//        you are not already in a session
//        you do not already have a request pending from someone else
//        you are online
//        requesting user is online
        let requestingUidObservable = observables.requestingUserObservable ?? createConnectionRequestUidObservable()
        let isOnlineObservable = requestingUidObservable?.flatMap { createUserOnlineObservable(withUid: $0) }
        let pendingObservable = observables.pendingRequestObservable ?? createPendingRequestObservable()
        let amOnlineObservable = observables.amOnlineObservable ?? createAmOnlineObservable()
        return Observable.combineLatest(isOnlineObservable!, pendingObservable!, amOnlineObservable) { isOnline, amPending, amOnline -> Bool in
            return isOnline && !amPending && amOnline && Auth.auth().currentUser != nil
            }.filter { $0 }
            .flatMap { _ -> Observable<LocalUser> in
                return createRequestingUserObservable()!
            }
    }
    
    /// Create observable that fetches requesting user
    static func createRequestingUserObservable() -> Observable<LocalUser>? {
        let requestingUserObservable = observables.requestingUserObservable ?? createConnectionRequestUidObservable()
        return requestingUserObservable?.flatMap { fetchObservableUser(withUid: $0) }
    }
    
    /// Create observable to monitor incoming request user uid's
    static func createConnectionRequestUidObservable() -> Observable<String>? {
        if let observable = observables.requestingUserObservable { return observable }
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        observables.requestingUserObservable = rxFirebaseListener(forRef: usersRef.child(uid).child("requestingUser"), andEvent: .value)
            .map { $0.value as! String }
            .filter { !$0.isEmpty }
            .share()
        return observables.requestingUserObservable
    }
    
    /// Create observable from current pending status
    static func createPendingRequestObservable() -> Observable<Bool>? {
        if let observable = observables.pendingRequestObservable { return observable }
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        observables.pendingRequestObservable = rxFirebaseListener(forRef: usersRef.child(uid).child("pendingRequest"), andEvent: .value)
            .map { $0.value as! Bool }
            .share()
        return observables.pendingRequestObservable
    }
    
    /// Create single event observable for user with uid
    static func createUserOnlineObservable(withUid uid: String) -> Observable<Bool> {
        return rxFirebaseSingleEvent(forRef: usersRef.child(uid).child("isOnline"), andEvent: .value)
            .filter { $0.value is Bool }
            .map { $0.value as! Bool }
    }
    
    /// Create obserable for if you are currently online
    static func createAmOnlineObservable() -> Observable<Bool> {
        if let observable = observables.amOnlineObservable { return observable }
        observables.amOnlineObservable = rxFirebaseListener(forRef: Database.database().reference(withPath: ".info/connected"), andEvent: .value)
            .map { $0.value as! Bool }
            .share()
        return observables.amOnlineObservable!
    }
    
    /// Check for connection initialized
    static func observeConnection(handler: @escaping((String) -> (Void))) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let connectedToRef = usersRef.child(uid).child("connectedTo")
        connectedToRef.observe(.value) { (snapshot) in
            if let connectedTo = snapshot.value as? String {
                if !connectedTo.isEmpty {
                    handler(connectedTo)
                }
            }
        }
        observedReferences.append(connectedToRef)
    }
    
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
    
    static func observePending(handler: @escaping (() -> Void)) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = usersRef.child(uid).child("pendingRequest")
        userRef.observe(.value) { (snapshot) in
            if let isPending = snapshot.value as? Bool {
                if !isPending {
                    handler()
                    userRef.child("pendingRequest").removeAllObservers()
                }
            }
        }
        observedReferences.append(userRef)
    }
//    static func checkOnline(handler: @escaping ((Bool) -> Void)) {
//        let connectedRef = Database.database().reference(withPath: ".info/connected")
//        connectedRef.observe(.value) { (snapshot) in
//            guard let uid = Auth.auth().currentUser?.uid else { return }
//            let connected = snapshot.value as? Bool ?? false
//            if connected {
//                usersRef.child(uid).updateChildValues(["isOnline" : true])
//            }else {
//                usersRef.child(uid).updateChildValues(["isOnline" : false])
//            }
//            handler(connected)
//        }
//        observedReferences.append(connectedRef)
//    }
}
