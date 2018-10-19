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
            
            guard let uid = data?.user.uid else{
                return
            }
            self.userId = uid
            let ref = Database.database().reference(fromURL: "https://ar-connect.firebaseio.com/")
            let usersReference = ref.child("Users").child(uid)
            let values = ["name": name, "email":email]
            usersReference.updateChildValues(values, withCompletionBlock:
            { (error, ref) in
                if let err = error {
                    let alert = UIAlertController(title: "Authorization error", message: err.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                    controller.present(alert, animated: true, completion: nil)
                    return
                }
                print("hi")
                AppDelegate.shared.rootViewController.switchToMainScreen()
            })
        }
    }
    
    // Request from view controller to log in to the database
    func logInToDB(email: String,password: String,controller: UIViewController){
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if let err = error {
                controller.createAndDisplayAlert(withTitle: "Authorization error", body: err.localizedDescription)
                return
            }
            AppDelegate.shared.rootViewController.switchToMainScreen()
        }
    }
    
    // Log out current user and return to login screen
    @objc func logoutOfDB(controller: UIViewController) {
        do{
            try Auth.auth().signOut()
        }catch let logoutError {
            print(logoutError)
            controller.createAndDisplayAlert(withTitle: "Log out error", body: logoutError.localizedDescription)
            return
        }
        locationModel.locationManager.stopUpdatingLocation()
        AppDelegate.shared.rootViewController.switchToLogout()
        
    }
}
