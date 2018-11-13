//
//  CellDetailViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 11/8/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase

class CellDetailViewController: UIViewController {

    
    @IBOutlet weak var cancelButton: UIButton!
    @IBAction func onCancel(_ sender: UIButton) {
        view.isHidden = true
    }
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var connectButton: UIButton!
    @IBAction func connectToUser(_ sender: UIButton) {
        if let uid = user?.uid {
            let userForCellRef = FirebaseClient.usersRef.child(uid)
            userForCellRef.updateChildValues(["connectedTo": uid])
        }
    }
    
    @IBAction func messageUser(_ sender: UIButton) {
        let messageVC = MessageViewController()
        self.navigationController?.pushViewController(messageVC, animated: true)
    }
    
    var user: LocalUser? {
        didSet {
            nameLabel.text = user?.name
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUIElements()
    }

    func setupUIElements() {
        cancelButton.setTitle("Cancel", for: .normal)
        messageButton.setTitle("Message", for: .normal)
        connectButton.setTitle("Connect", for: .normal)
    }
}
