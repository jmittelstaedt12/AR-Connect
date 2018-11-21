//
//  ConnectRequestViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 11/15/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase

protocol ConnectRequestDelegate {
    func startSession()
}
class ConnectRequestViewController: UIViewController {

    var delegate: ConnectRequestDelegate!
    var requestingUser: LocalUser!
    
    let requestingUserImageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .lightGray
        return view
    }()
    
    let requestingUserNameLabel: UILabel = {
        #warning("Build out this UI")
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    let acceptButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Confirm", for: .normal)
        btn.addTarget(self, action: #selector(handleResponse(sender:)), for: .touchUpInside)
        return btn
    }()
    
    let denyButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Deny", for: .normal)
        btn.addTarget(self, action: #selector(handleResponse(sender:)), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(requestingUserImageView)
        view.addSubview(acceptButton)
        view.addSubview(denyButton)
        setViewLayouts()
    }
    
    private func setViewLayouts() {
        requestingUserImageView.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: UIEdgeInsets(top: 60, left: 32, bottom: 0, right: -32))
        requestingUserImageView.centerAnchors(centerX: view.safeAreaLayoutGuide.centerXAnchor)
        requestingUserImageView.dimensionAnchors(height: view.frame.width - 64)
        acceptButton.edgeAnchors(top: requestingUserImageView.bottomAnchor, padding: UIEdgeInsets(top: 32, left: 0, bottom: 0, right: 0))
        acceptButton.centerAnchors(centerX: view.safeAreaLayoutGuide.centerXAnchor)
        denyButton.edgeAnchors(top: acceptButton.bottomAnchor, padding: UIEdgeInsets(top: 32, left: 0, bottom: 0, right: 0))
        denyButton.centerAnchors(centerX: view.safeAreaLayoutGuide.centerXAnchor)
    }
    
    @objc private func handleResponse(sender: UIButton) {
        guard let requestUid = requestingUser.uid, let uid = Auth.auth().currentUser?.uid else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        if sender.title(for: .normal) == "Confirm"{
            FirebaseClient.usersRef.child(uid).updateChildValues(["connectedTo" : requestUid,"requestingUser" : ""])
            FirebaseClient.usersRef.child(requestUid).updateChildValues(["connectedTo" : uid])
            delegate.startSession()
        } else {
            FirebaseClient.usersRef.child(uid).updateChildValues(["requestingUser" : ""])
        }
        FirebaseClient.usersRef.child(requestUid).updateChildValues(["pendingRequest" : false])
        self.dismiss(animated: true, completion: nil)
    }

}
