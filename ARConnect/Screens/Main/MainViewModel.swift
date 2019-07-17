//
//  MainViewModel.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/13/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Firebase
import MapKit

class MainViewModel: ViewModelProtocol {

    typealias ErrorMessage = (title: String, body: String)
    struct Input {
        let disconnectRequest: AnyObserver<Void>
        let logoutRequest: AnyObserver<Void>
    }

    struct Output {
        let profileImageDataObservable: Observable<Data>
        let connectRequestObservable: Observable<ConnectRequestViewModel>
        let endSessionObservable: Observable<Void>
        let sessionStartObservable: Observable<Result<String, FirebaseError>>
        let didSendConnectRequestObservable: Observable<Result<ConnectPendingViewModel, FirebaseError>>
    }

    let input: Input
    let output: Output

    private let disconnectRequestSubject = PublishSubject<Void>()
    private let logoutRequestSubject = PublishSubject<Void>()
    private let profileImageDataSubject = PublishSubject<Data>()
    private let connectRequestSubject = PublishSubject<ConnectRequestViewModel>()
    private let endSessionSubject = PublishSubject<Void>()
    private let sessionStartSubject = PublishSubject<Result<String, FirebaseError>>()
    private let didSendConnectRequestSubject = PublishSubject<Result<ConnectPendingViewModel, FirebaseError>>()
    private let disposeBag = DisposeBag()

    var uid: String
    var currentUser: LocalUser? {
        didSet {
            guard currentUser != nil, currentUser!.profileImageData == nil, let url = currentUser!.profileUrl else { return }
            NetworkRequests.profilePictureNetworkRequest(withUrl: url) { result in
                switch result {
                case .success(let data):
                    self.profileImageDataSubject.onNext(data)
                    self.currentUser!.profileImageData = data
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    let connectNotificationName = Notification.Name(NotificationConstants.requestResponseNotificationKey)
    var currentLocation: CLLocation?
    let firebaseClient: FirebaseClientType

    init(firebaseClient: FirebaseClientType = FirebaseClient()) {
        if firebaseClient.auth.user == nil {
            AppDelegate.shared.rootViewController.switchToLogout()
        }
        self.uid = firebaseClient.auth.user!.uid
        self.firebaseClient = firebaseClient
        self.firebaseClient.setOnDisconnectUpdates(forUid: uid)

        self.input = Input(disconnectRequest: disconnectRequestSubject.asObserver(),
                           logoutRequest: logoutRequestSubject.asObserver())
        self.output = Output(profileImageDataObservable: profileImageDataSubject,
                        connectRequestObservable: connectRequestSubject,
                        endSessionObservable: endSessionSubject,
                        sessionStartObservable: sessionStartSubject,
                        didSendConnectRequestObservable: didSendConnectRequestSubject)

        setNetworkObservers()
        setUIEventObservers()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleSessionStart(notification:)),
                                               name: connectNotificationName, object: nil)
    }

    private func setNetworkObservers() {

        // Fetch user profile image
        firebaseClient.fetchObservableUser(forUid: uid)
            .subscribe(onNext: { [weak self] user in
                guard let self = self else { return }
                self.currentUser = user
            })
            .disposed(by: disposeBag)

        // Online status observer
        firebaseClient.createAmOnlineObservable()
            .subscribe(onNext: { [weak self] connected in
                guard let self = self else { return }
                self.firebaseClient.usersRef.child(at: self.uid).updateChildValues(["isOnline": connected])
            })
            .disposed(by: disposeBag)

        // Setting connection request observer
        firebaseClient.willDisplayRequestingUserObservable()?
            .subscribe(onNext: { [weak self] (requestingUser, requestDictionary) in
                guard let self = self, let currentUser = self.currentUser, let currentLocation = self.currentLocation else {
                    return
                }
                let location = CLLocation(latitude: requestDictionary["latitude"] as! Double,
                                         longitude: requestDictionary["longitude"] as! Double)
                var connectRequestViewModel: ConnectRequestViewModel?
                if let url = requestingUser.profileUrl {
                    var requestingUserWithImageData = requestingUser
                    NetworkRequests.profilePictureNetworkRequest(withUrl: url) { result in
                        switch result {
                        case .success(let data):
                            requestingUserWithImageData.profileImageData = data
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                        connectRequestViewModel = ConnectRequestViewModel(currentUser: currentUser,
                                                                          requestingUser: requestingUserWithImageData,
                                                                          meetupLocation: location,
                                                                          currentLocation: currentLocation)
                        self.connectRequestSubject.onNext(connectRequestViewModel!)
                    }
                } else {
                    connectRequestViewModel = ConnectRequestViewModel(currentUser: currentUser,
                                                                      requestingUser: requestingUser,
                                                                      meetupLocation: location,
                                                                      currentLocation: currentLocation)
                    self.connectRequestSubject.onNext(connectRequestViewModel!)
                }
            })
            .disposed(by: disposeBag)
    }

    private func setUIEventObservers() {
        disconnectRequestSubject
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.firebaseClient.usersRef
                    .child(at: self.uid)
                    .updateChildValues(["connectedTo": "",
                                        "isConnected": false])
                self.endSessionSubject.onNext(())
                }, onCompleted: {
                    print("Completed")
                })
                .disposed(by: disposeBag)

        logoutRequestSubject
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                try? self.firebaseClient.logoutOfDB()
            })
            .disposed(by: disposeBag)
        }

    @objc func handleSessionStart(notification: NSNotification) {
        let connectedUid = notification.userInfo?["uid"] as! String
        let didConnect = notification.userInfo?["didConnect"] as! Bool
        guard didConnect else {
                sessionStartSubject.onNext(.failure(.unavailable))
                return
        }
        sessionStartSubject.onNext(.success(connectedUid))

        firebaseClient.usersRef.child(at: uid)
            .updateChildValues(["isPending": false,
                                "isConnected": true,
                                "connectedTo": connectedUid])

        firebaseClient.createEndSessionObservable(forUid: connectedUid)?
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.firebaseClient.usersRef
                    .child(at: self.uid)
                    .updateChildValues(["connectedTo": "",
                                        "isConnected": false])
                self.endSessionSubject.onNext(())
            })
            .disposed(by: disposeBag)
    }

    func requestToConnect(cellModel: UserCellModel, location: CLLocation) {
        firebaseClient.usersRef.child(at: self.uid).updateChildValues(["pendingRequest": true]) { [weak self] (error, _) in
            guard let self = self else { return }
            if let err = error {
                self.didSendConnectRequestSubject.onNext(.failure(.custom(title: "Networking Error", errorDescription: err.localizedDescription)))
                return
            }
            self.firebaseClient.createCallUserObservable(forUid: cellModel.uid,
                                                    atCoordinate: (latitude: location.coordinate.latitude,
                                                                        longitude: location.coordinate.longitude))

                .subscribe(onNext: { [weak self] completed in
                    guard let self = self else { return }
                    guard let currentUser = self.currentUser, let currentLocation = self.currentLocation else {
                        self.didSendConnectRequestSubject.onNext(.failure(.custom(title: "Network Error", errorDescription: "Your location is not currently available")))
                        return
                    }
                    guard completed else {
                        self.didSendConnectRequestSubject.onNext(.failure(.unavailable))
                        return
                    }
                    self.didSendConnectRequestSubject.onNext(.success(ConnectPendingViewModel(currentUser: currentUser,
                                                                                               requestingUser: cellModel.user,
                                                                                               meetupLocation: location,
                                                                                               currentLocation: currentLocation,
                                                                                               firebaseClient: FirebaseClient())))
                }, onError: { [weak self] error in
                    self?.didSendConnectRequestSubject.onNext(.failure(error as! FirebaseError))
                })
                .disposed(by: self.disposeBag)
        }
    }
}
