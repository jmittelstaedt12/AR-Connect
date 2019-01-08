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
        
        // set accept button constraints
        acceptButton.edgeAnchors(top: requestingUserNameLabel.bottomAnchor, padding: UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0))
        acceptButton.centerAnchors(centerX: view.safeAreaLayoutGuide.centerXAnchor)
        
        // set cancel button constriants
        cancelButton.edgeAnchors(top: acceptButton.bottomAnchor, padding: UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0))
        cancelButton.centerAnchors(centerX: view.safeAreaLayoutGuide.centerXAnchor)
    }
    
    override func handleResponse(sender: UIButton) {
        guard let requestUid = user.uid, let uid = Auth.auth().currentUser?.uid else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        if sender.title(for: .normal) == "Confirm" {
            FirebaseClient.usersRef.child(uid).updateChildValues(["connectedTo" : requestUid,"requestingUser" : ""])
            FirebaseClient.usersRef.child(uid).updateChildValues(["connectedTo" : requestUid]) { (error, ref) in
                if let err = error {
                    print(err.localizedDescription)
                    return
                }
                FirebaseClient.usersRef.child(requestUid).updateChildValues(["connectedTo" : uid], withCompletionBlock: { (error, ref) in
                    if let err = error {
                        print(err.localizedDescription)
                        return
                    }
                    let name = Notification.Name(rawValue: NotificationConstants.connectionNotificationKey)
                    NotificationCenter.default.post(name: name, object: nil, userInfo: ["user" : self.user as Any])
                })
            }
        } else {            
            FirebaseClient.usersRef.child(uid).updateChildValues(["requestingUser" : ""])
        }
        FirebaseClient.usersRef.child(requestUid).updateChildValues(["pendingRequest" : false])
        self.dismiss(animated: true, completion: nil)
    }

}
