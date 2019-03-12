//
//  ConnectRequestViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 11/15/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase

final class ConnectRequestViewController: ConnectViewController {

    var acceptButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Confirm", for: .normal)
        btn.addTarget(self, action: #selector(handleResponse(sender:)), for: .touchUpInside)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(acceptButton)
        setViewLayouts()
        setObservers()
    }

    override func setViewLayouts() {
        // Set profile image view constraints
        requestingUserImageView.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, padding: UIEdgeInsets(top: 30, left: 32, bottom: 0, right: 0))
        requestingUserImageView.dimensionAnchors(height: 80, width: 80)

        // Set name label constraints
        requestingUserNameLabel.edgeAnchors(leading: requestingUserImageView.trailingAnchor, bottom: requestingUserImageView.bottomAnchor, padding: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0))
        requestingUserNameLabel.dimensionAnchors(height: 20)

        // Set map view constraints
        meetupLocationMapView.edgeAnchors(top: requestingUserImageView.bottomAnchor, padding: UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0))
        meetupLocationMapView.centerAnchors(centerX: view.safeAreaLayoutGuide.centerXAnchor)
        meetupLocationMapView.dimensionAnchors(width: view.safeAreaLayoutGuide.widthAnchor, widthConstant: -16)
        meetupLocationMapView.dimensionAnchors(height: 100)

        // set accept button constraints
        acceptButton.edgeAnchors(top: meetupLocationMapView.bottomAnchor, padding: UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0))
        acceptButton.centerAnchors(centerX: view.safeAreaLayoutGuide.centerXAnchor)

        // set cancel button constriants
        cancelButton.edgeAnchors(top: acceptButton.bottomAnchor, padding: UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0))
        cancelButton.centerAnchors(centerX: view.safeAreaLayoutGuide.centerXAnchor)
    }

    private func setObservers() {
        FirebaseClient.createCallDroppedObservable(forUid: user.uid)?.subscribe(onNext: { [weak self] _ in
            guard let self = self, let uid = Auth.auth().currentUser?.uid else { return }
            FirebaseClient.usersRef.child(uid).child("requestingUser").updateChildValues(["uid": "", "latitude": 0, "longitude": 0])
            self.createAndDisplayAlert(withTitle: "Call Dropped", body: "Ending call")
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: bag)
    }

    override func handleResponse(sender: UIButton) {
        guard let requestUid = user.uid, let uid = Auth.auth().currentUser?.uid else {
            self.dismiss(animated: true, completion: nil)
            return
        }

        let group = DispatchGroup()
        group.enter()
        if sender.title(for: .normal) == "Confirm" {
            group.enter()
            FirebaseClient.usersRef.child(uid).updateChildValues(["isConnected": true, "connectedTo": requestUid]) { (error, _) in
                if let err = error {
                    print(err.localizedDescription)
                    return
                }
                group.leave()
            }

            group.enter()
            FirebaseClient.usersRef.child(requestUid).updateChildValues(["isConnected": true]) { (error, _) in
                if let err = error {
                    print(err.localizedDescription)
                    return
                }
                group.leave()
            }
        }
        group.leave()
        group.notify(queue: .main) {
            FirebaseClient.usersRef.child(uid).child("requestingUser").updateChildValues(["uid": ""])
            let name = Notification.Name(rawValue: NotificationConstants.requestResponseNotificationKey)
            let didConnect = (sender.title(for: .normal) == "Confirm") ? true : false
            NotificationCenter.default.post(name: name, object: nil, userInfo: ["user": self.user,
                                                                                "meetupLocation": self.meetupLocation,
                                                                                "didConnect": didConnect])
            self.dismiss(animated: true, completion: nil)
        }
    }
}
