//
//  MainViewModel.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/13/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Foundation
import RxSwift
import Firebase
import MapKit
import UIKit

class MainViewModel: ViewModelProtocol {

    typealias ConnectRequest = (requestingUser: LocalUser, meetupLocation: CLLocation)

    struct Input {
        let disconnectDidTap: AnyObserver<Void>
    }

    struct Output {
        let authenticatedUserObservable: Observable<Bool>
        let userImageDataObservable: Observable<Data>
        let connectRequestObservable: Observable<ConnectRequest>
        let endSessionObservable: Observable<Void>
        let sessionStartObservable: Observable<String?>
        let sendingConnectRequestObservable: Observable<Error?>
    }

    let input: Input
    let output: Output

    private let disconnectDidTapSubject = PublishSubject<Void>()
    private let isAuthenticatedSubject = PublishSubject<Bool>()
    private let userImageDataSubject = PublishSubject<Data>()
    private let connectRequestSubject = PublishSubject<ConnectRequest>()
    private let endSessionSubject = PublishSubject<Void>()
    private let sessionStartSubject = PublishSubject<String?>()
    private let sendingConnectRequestSubject = PublishSubject<Error?>()

    var currentUser: User!
    let disposeBag = DisposeBag()
    let connectNotificationName = Notification.Name(NotificationConstants.requestResponseNotificationKey)

    
    init() {
        input = Input(disconnectDidTap: disconnectDidTapSubject.asObserver())
        output = Output(authenticatedUserObservable: isAuthenticatedSubject.asObserver(),
                        userImageDataObservable: userImageDataSubject.asObserver(),
                        connectRequestObservable: connectRequestSubject.asObserver(),
                        endSessionObservable: endSessionSubject.asObserver(),
                        sessionStartObservable: sessionStartSubject.asObserver(),
                        sendingConnectRequestObservable: sendingConnectRequestSubject.asObserver())

        if Auth.auth().currentUser == nil {
            AppDelegate.shared.rootViewController.switchToLogout()
        }
        currentUser = Auth.auth().currentUser!
        FirebaseClient.setOnDisconnectUpdates(forUid: currentUser.uid)

        setUserObservers()
        setUIEventObservers()

        NotificationCenter.default.addObserver(self, selector: #selector(handleSessionStart(notification:)), name: connectNotificationName, object: nil)
    }

    private func setUserObservers() {

        /// Observe if current user becomes invalid
        Variable<User?>(Auth.auth().currentUser).asObservable()
            .subscribe(onNext: { [weak self] currentUser in
                if currentUser == nil {
                    self?.isAuthenticatedSubject.onNext(false)
                    return
                }
            })
            .disposed(by: disposeBag)

        /// Fetch user data
        FirebaseClient.fetchObservableUser(forUid: currentUser.uid)
            .subscribe(onNext: { [weak self] user in
                if let url = user.profileUrl {
                    self?.fetchUserImage(url: url)
                }
            })
            .disposed(by: disposeBag)

        /// Online status observer
        FirebaseClient.createAmOnlineObservable()
            .subscribe(onNext: { [weak self] connected in
                guard let uid = self?.currentUser?.uid else { return }
                FirebaseClient.usersRef.child(uid).updateChildValues(["isOnline": connected])
            })
            .disposed(by: disposeBag)

        /// Setting connection request observer
        FirebaseClient.willDisplayRequestingUserObservable()?
            .subscribe(onNext: { [weak self] (requestingUser, requestDictionary) in
                let location = CLLocation(latitude: requestDictionary["latitude"] as! Double,
                                         longitude: requestDictionary["longitude"] as! Double)

                self?.connectRequestSubject.onNext(ConnectRequest(requestingUser: requestingUser, meetupLocation: location))
            })
            .disposed(by: disposeBag)
    }

    private func setUIEventObservers() {
        disconnectDidTapSubject
            .subscribe(onNext: { [weak self] in
                if let self = self {
                    FirebaseClient.usersRef
                        .child(self.currentUser.uid)
                        .updateChildValues(["connectedTo": "",
                                            "isConnected": false])
                }
//                self?.endSessionSubject.onNext(())
            })
            .disposed(by: disposeBag)
    }

    private func fetchUserImage(url: URL) {
        NetworkRequests.profilePictureNetworkRequest(withUrl: url) { [weak self] data in
            self?.userImageDataSubject.onNext(data)
        }
    }

    @objc func handleSessionStart(notification: NSNotification) {
        let user = notification.userInfo?["user"] as! LocalUser
        let didConnect = notification.userInfo?["didConnect"] as! Bool
        guard let uid = user.uid, didConnect else {
                sessionStartSubject.onNext("\(user.name ?? "User") is unavailable")
                return
        }
        sessionStartSubject.onNext(nil)

        FirebaseClient.usersRef.child(currentUser.uid)
            .updateChildValues(["isPending": false,
                                "isConnected": true,
                                "connectedTo": uid])

        FirebaseClient.createEndSessionObservable(forUid: user.uid)?
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                FirebaseClient.usersRef
                    .child(self.currentUser.uid)
                    .updateChildValues(["connectedTo": "",
                                        "isConnected": false])
                self.endSessionSubject.onNext(())
            })
            .disposed(by: disposeBag)
    }

    private func requestToConnectWithUser(_ user: LocalUser, atCoordinate coordinate: CLLocationCoordinate2D) {
        FirebaseClient.usersRef.child(Auth.auth().currentUser!.uid)
            .updateChildValues(["pendingRequest": true]) { [weak self] (error, _) in
                guard let self = self else { return }
                if let err = error {
                    self.sendingConnectRequestSubject.onNext(err)
                    return
                }
                FirebaseClient.createCallUserObservable(forUid: user.uid!, atCoordinateTuple: (latitude: coordinate.latitude, longitude: coordinate.longitude))
                    .subscribe(onNext: { [weak self] completed in
                        guard completed else { return }
                        self?.sendingConnectRequestSubject.onNext(nil)
                    }, onError: { [weak self] error in
                        self?.sendingConnectRequestSubject.onNext(error)
                    })
                    .disposed(by: self.disposeBag)
        }
    }
}
