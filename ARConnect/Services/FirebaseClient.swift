//
//  FirebaseClient.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/9/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import Firebase
import Foundation
import RxSwift

fileprivate struct FIRObservables {
    var usersObservable: Observable<[LocalUser]>?
    var requestingUserUidObservable: Observable<String>?
    var requestIsPendingObservable: Observable<Bool>?
    var amOnlineObservable: Observable<Bool>?
    var amInSessionObservable: Observable<Bool>?
}

fileprivate var observables = FIRObservables()

class FirebaseClient {

    let auth: JMAuth
    let usersRef: DatabaseReference
    var observedReferences = [DatabaseReference]()

    init() {
        let firebase = Firebase(functionality: .network)
        auth = firebase.auth
        usersRef = firebase.usersRef
    }
    
    init(firebase: Firebase) {
        auth = firebase.auth
        usersRef = firebase.usersRef
    }
//    let usersRef = Database.database().reference().child("Users")

    /// Request to authorize a new user and add them to database
    func createNewUser(user: RegisterUser, handler: @escaping ((Error?) -> Void)) {
        guard let png = user.pngData else {
            registerNewUser(user: user, handler: handler)
            return
        }
        let imageName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("\(imageName).png")
        storageRef.putData(png, metadata: nil) { [weak self] (_, error) in
            guard let self = self else { return }
            if let err = error {
                handler(err)
                return
            }
            storageRef.downloadURL { (url, error) in
                if let err = error {
                    handler(err)
                    return
                }
                self.registerNewUser(user: user, imageUrl: url?.absoluteString, handler: handler)
            }
        }
    }

    func registerNewUser(user: RegisterUser, imageUrl: String? = nil, handler: @escaping ((Error?) -> Void)) {
        auth.createUser(withEmail: user.email, password: user.password) { [weak self] (data, error) in
            guard let self = self else { return }
            if let err = error {
                handler(err)
                return
            }
            guard let uid = data?.user.uid else { return }

            var postError: Error?
            let userReference = self.usersRef.child(uid)
            let requestingUserReference = userReference.child("requestingUser")

            let values = ["email": user.email!,
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
    func logInToDB(email: String, password: String) -> Observable<Result<LocalUser, Error>> {
        return Observable.create({ observer -> Disposable in
            self.auth.signIn(withEmail: email, password: password) { result in
                switch result {
                case .success(let user):
                    observer.onNext(.success(user))
                case .failure(let error):
                    observer.onNext(.failure(error))
                }
            }
            return Disposables.create()
        })
    }

    /// Log out current user and return to login screen
    func logoutOfDB() throws {
        guard let uid = auth.currentUser?.uid else { return }
        for ref in observedReferences {
            ref.removeAllObservers()
        }
        do {
            try auth.signOut()
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

//    func sendConnectRequestToUser(withUid uid: String, atCoordinateTuple coordinate: (latitude: Double, longitude: Double)) -> Observable<String> {
//        #warning("combine with createCanCallObservable")
//        return Observable.create({ (observer) -> Disposable in
//            FirebaseClient.usersRef.child(auth.currentUser!.uid).updateChildValues(["pendingRequest": true])
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

    func setOnDisconnectUpdates(forUid uid: String) {
        let userRef = usersRef.child(uid)
        userRef.onDisconnectUpdateChildValues(["connectedTo": "",
                                               "isOnline": false,
                                               "pendingRequest": false,
                                               "isConnected": false])
        userRef.child("requestingUser").onDisconnectUpdateChildValues(["uid": "",
                                                                       "latitude": 0,
                                                                       "longitude": 0])
    }

    func rxFirebaseSingleEvent(forRef ref: DatabaseQuery, andEvent event: DataEventType) -> Observable<DataSnapshot> {
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

    func rxFirebaseListener(forRef ref: DatabaseQuery, andEvent event: DataEventType) -> Observable<DataSnapshot> {
        return Observable.create { (observer) -> Disposable in
            ref.observe(event, with: { (snapshot) in
                observer.onNext(snapshot)
            }, withCancel: { (error) in
                observer.onError(error)
            })
            return Disposables.create()
        }
    }

    func fetchObservableUser(forUid uid: String) -> Observable<LocalUser> {
        return rxFirebaseSingleEvent(forRef: usersRef.child(uid), andEvent: .value)
            .filter { $0.value is [String: AnyObject] }
            .map { snapshot in
                let dictionary = snapshot.value as! [String: AnyObject]
                var user = LocalUser()
                user.name = dictionary["name"] as! String
                user.email = dictionary["email"] as! String
                user.uid = uid
                if let urlString = dictionary["profileImageUrl"] as? String, !urlString.isEmpty, let url = URL(string: urlString) { user.profileUrl = url }
                return user
        }
    }

    enum FetchUsersObservableType {
        case singleEvent
        case continuous
    }

    /// Fetch all the users currently in the database as an observable
    func fetchObservableUsers(withObservableType type: FetchUsersObservableType, queryReference: DatabaseQuery? = nil) -> Observable<[LocalUser]> {
        if let observable = observables.usersObservable, type == .continuous { return observable }
        observables.usersObservable = rxFirebaseListener(forRef: queryReference ?? usersRef, andEvent: .value)
        .filter { $0.value is [String: AnyObject] }
            .map { snapshot in
                var dictionary = snapshot.value as! [String: AnyObject]
                if let uid = self.auth.currentUser?.uid {
                    dictionary.removeValue(forKey: uid)
                }
                var users = dictionary.values
                    .filter { $0 is [String: AnyObject] }
                    .map { $0 as! [String: AnyObject] }
                    .map { userDictionary -> LocalUser in
                        var user = LocalUser()
                        user.name = userDictionary["name"] as! String
                        user.email = userDictionary["email"] as! String
                        user.isOnline = userDictionary["isOnline"] as! Bool
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

    func fetchRequestingUser(uid: String) -> Observable<(LocalUser, [String: AnyObject])> {
        return Observable.create { (observer) -> Disposable in
            let currentUserRef = self.usersRef.child(self.auth.currentUser!.uid)
            let requestingUserRef = self.usersRef.child(uid)

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
                    requestingUser.name = dictionary["name"] as! String
                    requestingUser.email = dictionary["email"] as! String
                    if let urlString = dictionary["profileImageUrl"] as? String, !urlString.isEmpty, let url = URL(string: urlString) {
                        requestingUser.profileUrl = url
                    }
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
//    func createRequestingUserObservable() -> Observable<LocalUser>? {
//        let requestingUserObservable = createRequestingUserUidObservable()
//        return requestingUserObservable?
//            .flatMapLatest { fetchObservableUser(forUid: $0) }
//            .share(replay: 1)
//    }

    /// Create observable to monitor incoming request user uid's
    func createRequestingUserUidObservable() -> Observable<String>? {
        if let observable = observables.requestingUserUidObservable { return observable }
        guard let uid = auth.currentUser?.uid else { return nil }
        observables.requestingUserUidObservable = rxFirebaseListener(forRef: usersRef.child(uid).child("requestingUser").child("uid"), andEvent: .value)
            .filter { $0.value is String }
            .map { $0.value as! String }
            .filter { !$0.isEmpty }
            .share(replay: 1)
        return observables.requestingUserUidObservable
    }

    func createNoRequestingUserObservable(forUid uid: String) -> Observable<Bool> {
        return rxFirebaseListener(forRef: usersRef.child(uid).child("requestingUser").child("uid"), andEvent: .value)
            .filter { $0.value is String }
            .map { $0.value as! String }
            .map { $0.isEmpty }
            .filter { $0 }
    }

    /// Create requesting user for uid observable
    func createRequestIsPendingObservable(forUid uid: String) -> Observable<Bool> {
        if uid == auth.currentUser?.uid, let observable = observables.requestIsPendingObservable { return observable }
        let requestIsPendingObservable = rxFirebaseListener(forRef: usersRef.child(uid).child("pendingRequest"), andEvent: .value)
            .filter { $0.value is Bool }
            .map { $0.value as! Bool }
            .share(replay: 1)
        if uid == auth.currentUser?.uid { observables.requestIsPendingObservable = requestIsPendingObservable }
        return requestIsPendingObservable
    }

    /// Create single event observable for user online with uid
    func createUserOnlineObservable(forUid uid: String) -> Observable<Bool> {
        return rxFirebaseListener(forRef: usersRef.child(uid).child("isOnline"), andEvent: .value)
            .filter { $0.value is Bool }
            .map { $0.value as! Bool }
    }

    /// Create obserable to monitor if you are currently online
    func createAmOnlineObservable() -> Observable<Bool> {
        if let observable = observables.amOnlineObservable { return observable }
        observables.amOnlineObservable = rxFirebaseListener(forRef: Database.database().reference(withPath: ".info/connected"), andEvent: .value)
            .filter { $0.value is Bool }
            .map { $0.value as! Bool }
            .share(replay: 1)
        return observables.amOnlineObservable!
    }

    /// Create observable to check if user is available to connect
    func createUserAvailableObservable(forUid uid: String) -> Observable<Bool> {
        let isOnlineObservable = createUserOnlineObservable(forUid: uid)
        let isInSessionObservable = rxFirebaseSingleEvent(forRef: usersRef.child(uid).child("isConnected"), andEvent: .value)
            .filter { $0.value is Bool }
            .map { $0.value as! Bool }

        let isPendingObservable = rxFirebaseSingleEvent(forRef: usersRef.child(uid).child("pendingRequest"), andEvent: .value)
            .filter { $0.value is Bool }
            .map { $0.value as! Bool }

        return Observable.combineLatest(isOnlineObservable, isInSessionObservable, isPendingObservable) { return $0 && !$1 && !$2 }.take(1)
    }

    func createCallUserObservable(forUid uid: String, atCoordinate coordinate: (latitude: Double, longitude: Double)) -> Observable<Bool> {
        let currentUid = auth.currentUser!.uid
        let isAvailableObservable = createUserAvailableObservable(forUid: uid)
        let amOnlineObservable = createAmOnlineObservable()
        return Observable.combineLatest(isAvailableObservable, amOnlineObservable) {
            if !$0 {
                throw FirebaseError.unavailable
            }
            if !$1 { throw FirebaseError.amOffline }
            return $0 && $1
            }
            .filter { $0 }
            .flatMap { _ in return Observable.create({ (observer) -> Disposable in
                    let requestingUserRef = self.usersRef.child(uid).child("requestingUser")
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

    func willDisplayRequestingUserObservable() -> Observable<(LocalUser, [String: AnyObject])>? {
        guard let currentUid = auth.currentUser?.uid else { return nil }
        let requestingUidObservable = createRequestingUserUidObservable() // get requesting uid
        let isOnlineObservable = requestingUidObservable?.flatMap { self.createUserOnlineObservable(forUid: $0) } // requesting user is available
        let pendingObservable = createRequestIsPendingObservable(forUid: currentUid) // you are not awaiting a response from someone else
        let amOnlineObservable = createAmOnlineObservable() // you are online

        return Observable.combineLatest(isOnlineObservable!, pendingObservable, amOnlineObservable) { [weak self] isOnline, amPending, amOnline -> Bool in
            guard let self = self else { return false }
            return isOnline && !amPending && amOnline && self.auth.currentUser != nil
        }
            .filter { $0 }
            .flatMapLatest { _ -> Observable<String> in
                return self.createRequestingUserUidObservable()!
            }
            .flatMapLatest { uid -> Observable<(LocalUser, [String: AnyObject])> in
                return self.fetchRequestingUser(uid: uid)
            }
            .share(replay: 1)
    }

    func createCallDroppedObservable(forUid uid: String) -> Observable<Bool>? {
        let requestIsPendingObservable = createRequestIsPendingObservable(forUid: uid)
        let isInSessionObservable = createIsInSessionObservable(forUid: uid)
        return requestIsPendingObservable
            .filter { !$0 }
            .flatMapLatest { _ in return isInSessionObservable }
            .filter { !$0 }
    }

    func createCalledUserResponseObservable(forUid uid: String) -> Observable<Bool>? {
        guard let currentUid = auth.currentUser?.uid else { return nil }
        return createNoRequestingUserObservable(forUid: uid)
            .flatMapLatest { _ in return self.createIsInSessionObservable(forUid: currentUid) }
            .take(1)
    }

    func createIsInSessionObservable(forUid uid: String) -> Observable<Bool> {
        if uid == auth.currentUser?.uid, let observable = observables.amInSessionObservable { return observable }
        let isInSessionObservable = rxFirebaseListener(forRef: usersRef.child(uid).child("isConnected"), andEvent: .value)
            .filter { $0.value is Bool }
            .map { $0.value as! Bool }
        if uid == auth.currentUser?.uid { observables.amInSessionObservable = isInSessionObservable }
        return isInSessionObservable
    }

    func createEndSessionObservable(forUid uid: String) -> Observable<Bool>? {
        guard let currentUid = auth.currentUser?.uid else { return nil }
        let amInSessionObservable = createIsInSessionObservable(forUid: currentUid)
        let isInSessionObservable = createIsInSessionObservable(forUid: uid)
        return Observable.combineLatest(amInSessionObservable, isInSessionObservable) { return !$0 || !$1 }
            .filter { $0 }
            .take(1)
    }

//    func createConnectedUserCoordinatesObservable(userUid uid: String) -> Observable<(Double?, Double?)> {
//        let latitudeObservable = rxFirebaseListener(forRef: usersRef.child(uid).child("latitude"), andEvent: .value)
//        let longitudeObservable = rxFirebaseListener(forRef: usersRef.child(uid).child("latitude"), andEvent: .value)
////        return latitudeObservable.concat(longitudeObservable)
//    }

    func fetchCoordinates(uid: String, handler: @escaping((Double?, Double?) -> Void)) {
        let userRef = usersRef.child(uid)
        userRef.observeSingleEvent(of: .value) { (snapshot) in
            if let userDictionary = snapshot.value as? [String: Any] {
                let latitude = userDictionary["latitude"] as? Double
                let longitude = userDictionary["longitude"] as? Double
                handler(latitude, longitude)
            } else {
                handler(nil, nil)
            }
        }
    }

}

enum FirebaseError: LocalizedError {
    case noResponse(userName: String?)
    case isOffline(userName: String?)
    case unavailable
    case amOffline
    case custom(title: String, errorDescription: String)
    public var title: String {
        switch self {
        case .noResponse(_):
            return "Timed Out"
        case .isOffline:
            return "Connection Error"
        case .unavailable:
            return "Connection Error"
        case .amOffline:
            return "Network Error"
        case .custom(let title, _):
            return title
        }
    }

    public var errorDescription: String {
        switch self {
        case .noResponse(let name):
            return NSLocalizedString("\(name ?? "User") did not respond", comment: "")
        case .isOffline:
            return NSLocalizedString("User is offline", comment: "")
        case .unavailable:
            return NSLocalizedString("User is unavailable", comment: "")
        case .amOffline:
            return NSLocalizedString("You are offline", comment: "")
        case .custom(_, let description):
            return NSLocalizedString(description, comment: "")
        }
    }
}
