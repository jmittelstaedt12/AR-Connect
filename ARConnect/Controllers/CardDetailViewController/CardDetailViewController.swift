//
//  CellDetailViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 11/8/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase

final class CardDetailViewController: UIViewController {
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var connectButton: UIButton!
    
    let currentUser = Auth.auth().currentUser
    
    var userForCell: LocalUser? {
        didSet {
            nameLabel.text = userForCell?.name
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupUIElements()
    }
    
    private func setupView() {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 5
        view.isHidden = true
    }

    func setupUIElements() {
        cancelButton.setTitle("Cancel", for: .normal)
        messageButton.setTitle("Message", for: .normal)
        connectButton.setTitle("Connect", for: .normal)
    }
    
    @IBAction func onCancel(_ sender: UIButton) {
        view.isHidden = true
    }
    
    @IBAction func connectToUser(_ sender: UIButton) {
        if let userForCellUid = userForCell?.uid, let currentUid = currentUser?.uid {
            let userForCellRef = FirebaseClient.usersRef.child(userForCellUid)
            let currentUserRef = FirebaseClient.usersRef.child(currentUid)
            userForCellRef.updateChildValues(["requestingUser": currentUid])
            currentUserRef.updateChildValues(["pendingRequest" : true])
            let connectPendingVC = ConnectPendingViewController()
            connectPendingVC.user = userForCell
            present(connectPendingVC, animated: true, completion: nil)
        }
        view.isHidden = true
    }
    
    @IBAction func messageUser(_ sender: UIButton) {
        let messageVC = MessageViewController()
        self.navigationController?.pushViewController(messageVC, animated: true)
    }
}
