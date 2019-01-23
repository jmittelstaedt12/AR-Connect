//
//  InheritingTestViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 1/8/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase

final class ConnectPendingViewController: ConnectViewController {
    
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cancelButton.setTitle("Cancel", for: .normal)
        setViewLayouts()
        setObservers()
        setTimer()
    }
    
    override func setViewLayouts() {
        // Set profile image view constraints
        requestingUserImageView.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: UIEdgeInsets(top: 60, left: 32, bottom: 0, right: -32))
        requestingUserImageView.centerAnchors(centerX: view.safeAreaLayoutGuide.centerXAnchor)
        requestingUserImageView.dimensionAnchors(height: view.frame.width - 64)
        
        // Set name label constraints
        requestingUserNameLabel.edgeAnchors(top: requestingUserImageView.bottomAnchor, padding: UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0))
        requestingUserNameLabel.centerAnchors(centerX: view.safeAreaLayoutGuide.centerXAnchor)
        requestingUserNameLabel.dimensionAnchors(height: 20)
        
        // set cancel button constriants
        cancelButton.edgeAnchors(top: requestingUserNameLabel.bottomAnchor, padding: UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0))
        cancelButton.centerAnchors(centerX: view.safeAreaLayoutGuide.centerXAnchor)
    }
    
    private func setObservers() {
        FirebaseClient.createAmOnlineObservable().subscribe(onNext: { [weak self] amOnline in
            if !amOnline {
                self?.dismiss(animated: true) {
                    self?.createAndDisplayAlert(withTitle: "Network Error", body: "You are offline")
                }
            }
        }).disposed(by: bag)
        
        FirebaseClient.createCalledUserResponseObservable(forUid: user.uid)?.subscribe(onNext: { [weak self] didConnect in
            if didConnect {
                // initialize AR session
                guard let self = self else { return }
                let name = Notification.Name(rawValue: NotificationConstants.connectionNotificationKey)
                NotificationCenter.default.post(name: name, object: nil, userInfo: ["user" : self.user as Any])
            } else {
                FirebaseClient.usersRef.child(Auth.auth().currentUser!.uid).updateChildValues(["pendingRequest" : false])
                self?.createAndDisplayAlert(withTitle: "Call Ending", body: "\(self?.user.name ?? "User") is unavailable")
            }
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: bag)
    }
    
    private func setTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] timer in
            FirebaseClient.usersRef.child(Auth.auth().currentUser!.uid).updateChildValues(["pendingRequest" : false])
            guard let self = self else { return }
            self.createAndDisplayAlert(withTitle: "Call Timed Out", body: "\(self.user.name ?? "User") did not respond")
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func handleResponse(sender: UIButton) {
        if sender.title(for: .normal) == "Cancel" {
            FirebaseClient.usersRef.child(Auth.auth().currentUser!.uid).updateChildValues(["pendingRequest" : false])
            timer?.invalidate()
            dismiss(animated: true, completion: nil)
        }
    }
    
}
