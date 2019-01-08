//
//  InheritingTestViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 1/8/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase
import RxSwift

final class ConnectPendingViewController: ConnectViewController {
    
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cancelButton.setTitle("Cancel", for: .normal)
        setViewLayouts()
        setObservers()
        setTimer()
    }
    
    private func setObservers() {
        FirebaseClient.createAmOnlineObservable().subscribe(onNext: { (amOnline) in
            if !amOnline {
                self.dismiss(animated: true) {
                    self.createAndDisplayAlert(withTitle: "Network Error", body: "Requested user not found")
                }
            }
        }).disposed(by: bag)
        
//        FirebaseClient.createCalledUserResponseObservable().subscribe(onNext: { (response) in
//
//        }).disposed(by: bag)
    }
    
    private func setTimer() {
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { (timer) in
            FirebaseClient.usersRef.child(Auth.auth().currentUser!.uid).updateChildValues(["pendingRequest" : false])
            self.createAndDisplayAlert(withTitle: "Call Timed Out", body: "\(self.user.name ?? "User") did not respond")
            self.dismiss(animated: true, completion: nil)
        }
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
    
    override func handleResponse(sender: UIButton) {
        if sender.title(for: .normal) == "Cancel" {
            let uid = Auth.auth().currentUser!.uid
            FirebaseClient.usersRef.child(uid).updateChildValues(["pendingRequest" : false])
            self.dismiss(animated: true, completion: nil)
        }
    }
}
