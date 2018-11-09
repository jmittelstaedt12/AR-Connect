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

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var connectButton: UIButton!
    @IBAction func connectToUser(_ sender: UIButton) {
        if let uid = user.uid {
            let userForCellRef = Database.database().reference().child("Users").child(uid)
            userForCellRef.updateChildValues(["connectedTo": uid])
        }
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func messageUser(_ sender: UIButton) {
        let messageVC = MessageViewController()
        self.navigationController?.pushViewController(messageVC, animated: true)
    }
    
    
    var user: LocalUser!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUIElements()
    }

    func setupUIElements() {
        nameLabel.text = user.name
        messageButton.setTitle("Message", for: .normal)
        connectButton.setTitle("Connect", for: .normal)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
