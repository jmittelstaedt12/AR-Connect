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

struct FirebaseClient {
    
    static let usersRef = Database.database().reference().child("Users")
    
    // Request to authorize a new user and add them to database
    static func createNewUser(name: String, email: String,password: String, controller: UIViewController) {
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
            let usersReference = usersRef.child(uid)
            let values = ["name": name, "email": email, "connectedTo": ""]
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
    static func logInToDB(email: String,password: String,controller: UIViewController){
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if let err = error {
                controller.createAndDisplayAlert(withTitle: "Authorization error", body: err.localizedDescription)
                return
            }
            AppDelegate.shared.rootViewController.switchToMainScreen()
        }
    }
    
    // Log out current user and return to login screen
    static func logoutOfDB(controller: UIViewController) -> Bool {
        do{
            try Auth.auth().signOut()
        }catch let logoutError {
            print(logoutError)
            controller.createAndDisplayAlert(withTitle: "Log out error", body: logoutError.localizedDescription)
            return false
        }
        return true
    }
    
    // Fetch all the users currently in the database
    static func fetchUsers(handler: @escaping (([LocalUser]) -> Void)) {
//        let usersReference = Database.database().reference().child("Users")
        var users = [LocalUser]()
        usersRef.observeSingleEvent(of: .value) { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                for child in dictionary.values {
                    if let userDictionary = child as? [String: String] {
                        let user = LocalUser()
                        user.name = userDictionary["name"]
                        user.email = userDictionary["email"]
                        users.append(user)
                    }
                }
                for (i,k) in dictionary.keys.enumerated(){
                    users[i].uid = k
                }
                handler(users)
            }
        }
    }
    
    // Add observer for connection request
    static func observeConnectionRequests(handler: @escaping ((String) -> Void)) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        let currentUserRef = usersRef.child(uid).child("connectedTo")
        currentUserRef.observe(.value) { (snapshot) in
            if let connectedTo = snapshot.value as? String {
                if !connectedTo.isEmpty {
                    print("connection request!")
                    handler(connectedTo)
                }
            }
        }
    }
    // See if user is connected to firebase
    static func checkOnline() {
        #warning("TODO: handle online stuff")
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value) { (snapshot) in
            if snapshot.value as? Bool ?? false {
                print("Connected")
            }else {
                print("Not connected")
            }
        }
    }
}
