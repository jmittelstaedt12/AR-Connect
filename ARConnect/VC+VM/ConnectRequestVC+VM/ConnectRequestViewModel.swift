//
//  ConnectRequestViewModel.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/22/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Foundation
import RxSwift
import MapKit
import Firebase

final class ConnectRequestViewModel: ViewModelProtocol {

    private let currentUser: LocalUser
    private let requestingUser: LocalUser
    let meetupLocation: CLLocation
    let currentLocation: CLLocation
    let nameString: String
    let profileImageData: Data?

    struct Input {

    }

    struct Output {
        let processedResponseObservable: Observable<Result<Void, FirebaseError>>
        let callDroppedObservable: Observable<Void>

    }

    let input: Input
    let output: Output

    private let processedResponseSubject = PublishSubject<Result<Void, FirebaseError>>()
    private let callDroppedSubject = PublishSubject<Void>()
    private let disposeBag = DisposeBag()

    init(currentUser: LocalUser, requestingUser: LocalUser, meetupLocation: CLLocation, currentLocation: CLLocation) {
        input = Input()
        output = Output(processedResponseObservable: processedResponseSubject,
                        callDroppedObservable: callDroppedSubject)
        self.currentUser = currentUser
        self.requestingUser = requestingUser
        self.meetupLocation = meetupLocation
        self.currentLocation = currentLocation
        self.nameString = requestingUser.name
        self.profileImageData = requestingUser.profileImageData
        setObservers()
    }

    private func setObservers() {
        FirebaseClient.createCallDroppedObservable(forUid: requestingUser.uid)?.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            FirebaseClient.usersRef.child(self.currentUser.uid).child("requestingUser")
                .updateChildValues(["uid": "", "latitude": 0, "longitude": 0])
            self.callDroppedSubject.onNext(())
        }).disposed(by: disposeBag)
    }

    func handleResponse(senderTitle: String) {
        let group = DispatchGroup()

        // Work item if firebase updates succeed
        let workItem = DispatchWorkItem {
            FirebaseClient.usersRef.child(self.currentUser.uid).child("requestingUser").updateChildValues(["uid": "",
                                                                                          "latitude": 0,
                                                                                          "longitude": 0])
            let name = Notification.Name(rawValue: NotificationConstants.requestResponseNotificationKey)
            let didConnect = (senderTitle == "Confirm") ? true : false
            NotificationCenter.default.post(name: name, object: nil, userInfo: ["uid": self.requestingUser.uid,
                                                                                "meetupLocation": self.meetupLocation,
                                                                                "didConnect": didConnect])
            self.processedResponseSubject.onNext(.success(()))
        }

        // Completion handler for firebase requests
        let updateCompletionHandler: (Error?, DatabaseReference) -> Void = {(error, _) in
            defer {
                group.leave()
            }
            if let err = error {
                workItem.cancel()
                self.processedResponseSubject.onNext(.failure(.custom(title: "Network Error", errorDescription: err.localizedDescription)))
                return
            }
        }
        if senderTitle == "Confirm" {
            let distance = currentLocation.distance(from: meetupLocation)
            if distance > 5000.0 {
                processedResponseSubject.onNext(.failure(.custom(title: "Too Far From Meetup Point",
                                                                 errorDescription: "Your distance of \(distance) is too far for accurate walking directions")))
                return
            }
            group.enter()
            FirebaseClient.usersRef.child(currentUser.uid).updateChildValues(["isConnected": true, "connectedTo": requestingUser.uid],
                                                                      withCompletionBlock: updateCompletionHandler)
            group.enter()
            FirebaseClient.usersRef.child(requestingUser.uid).updateChildValues(["isConnected": true],
                                                                                withCompletionBlock: updateCompletionHandler)
        }

        group.notify(queue: .main, work: workItem)
    }
}
