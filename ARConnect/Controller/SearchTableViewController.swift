//
//  SearchTableViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/31/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase

class SearchTableViewController: UITableViewController {

    var users = [LocalUser]()

    override func viewDidLoad() {
        super.viewDidLoad()
        let logoutButton = UIBarButtonItem(title: "Dismiss", style: .plain, target: self, action: #selector(dismissVC))
        navigationItem.setLeftBarButton(logoutButton, animated: true)
        Database.database().reference().child("Users").observe(.value) { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                
                for child in dictionary.values {
                    
                    if let userDictionary = child as? [String: String]{
                        let user = LocalUser()
                        user.name = userDictionary["name"]
                        user.email = userDictionary["email"]
                        self.users.append(user)
                    }
                }
                
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        #warning("to do")
//        let cell = UITableViewCell
//    }
    
    @objc private func dismissVC(){
        dismiss(animated: true, completion: nil)
    }
}
