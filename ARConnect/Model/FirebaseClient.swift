//
//  FirebaseClient.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/9/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import Foundation
import Firebase
import UIKit

class FirebaseClient {
    
    var userId: String?
    
    // Request to authorize a new user and add them to database
    func createNewUser(name: String, email: String,password: String, controller: UIViewController) {
        Auth.auth().createUser(withEmail: email, password: password) { (data, error) in
            if let err = error {
                let alert = UIAlertController(title: "Authorization error", message: err.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                controller.present(alert, animated: true, completion: nil)
                return
            }
            
            if let uid = data?.user.uid {
                self.userId = uid
            }
            
            let ref = Database.database().reference(fromURL: "https://ar-connect.firebaseio.com/")
            let usersReference = ref.child("Users")
            let values = ["name": name, "email":email]
            usersReference.updateChildValues(values, withCompletionBlock:
            { (error, ref) in
                if let err = error {
                    let alert = UIAlertController(title: "Authorization error", message: err.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                    controller.present(alert, animated: true, completion: nil)
                    return
                }
                AppDelegate.shared.rootViewController.switchToMainScreen()
            })
        }
    }
    
    // Request from view controller to log in to the database
    func logInToDB(email: String,password: String,controller: UIViewController){
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if let err = error {
                let alert = UIAlertController(title: "Authorization error", message: err.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                controller.present(alert, animated: true, completion: nil)
                return
            }
            AppDelegate.shared.rootViewController.switchToMainScreen()
        }
    }
}
