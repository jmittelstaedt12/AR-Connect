//
//  ConnectPendingViewModel.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/22/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Foundation
import RxSwift
import MapKit
import Firebase

final class ConnectPendingViewModel: ViewModelProtocol {

    private let currentUser: LocalUser
    private let requestingUser: LocalUser
    let meetupLocation: CLLocation
    let currentLocation: CLLocation
    let nameString: String
    let profileImageData: Data?
    var timer: Timer?

    struct Input {

    }

    struct Output {
        let wentOfflineObservable: Observable<FirebaseError>
        let receivedResponseObservable: Observable<Void>
        let callDroppedObservable: Observable<FirebaseError>
    }

    let input: Input
    let output: Output

    private let wentOfflineSubject = PublishSubject<FirebaseError>()
    private let receivedResponseSubject = PublishSubject<Void>()
    private let callDroppedSubject = PublishSubject<FirebaseError>()
    private let disposeBag = DisposeBag()

    init(currentUser: LocalUser, requestingUser: LocalUser, meetupLocation: CLLocation, currentLocation: CLLocation) {
        input = Input()
        output = Output(wentOfflineObservable: wentOfflineSubject,
                        receivedResponseObservable: receivedResponseSubject,
                        callDroppedObservable: callDroppedSubject)
        self.currentUser = currentUser
        self.requestingUser = requestingUser
        self.meetupLocation = meetupLocation
        self.currentLocation = currentLocation
        self.nameString = requestingUser.name
        self.profileImageData = requestingUser.profileImageData
        setObservers()
        setTimer()
    }

    func didCancel() {
        FirebaseClient.usersRef.child(currentUser.uid).updateChildValues(["pendingRequest": false])
        timer?.invalidate()
    }

    private func setObservers() {
        FirebaseClient.createAmOnlineObservable().subscribe(onNext: { [weak self] amOnline in
            if !amOnline {
                self?.wentOfflineSubject.onNext(.amOffline)
            }
        }).disposed(by: disposeBag)

        FirebaseClient.createCalledUserResponseObservable(forUid: requestingUser.uid)?
            .subscribe(onNext: { [weak self] didConnect in
                guard let self = self else { return }
                FirebaseClient.usersRef.child(self.currentUser.uid).updateChildValues(["pendingRequest": false])
                let name = Notification.Name(rawValue: NotificationConstants.requestResponseNotificationKey)
                NotificationCenter.default.post(name: name, object: nil, userInfo: ["uid": self.requestingUser.uid,
                                                                                    "meetupLocation": self.meetupLocation,
                                                                                    "didConnect": didConnect])
                self.receivedResponseSubject.onNext(())
            })
            .disposed(by: disposeBag)
    }

    private func setTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            FirebaseClient.usersRef.child(self.currentUser.uid).updateChildValues(["pendingRequest": false])
            self.callDroppedSubject.onNext(.noResponse(userName: self.requestingUser.name))
        }
    }
}
