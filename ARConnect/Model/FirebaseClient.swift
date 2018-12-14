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
    
    /// Request to authorize a new user and add them to database
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
            let values = ["email" : email,
                          "name" : name,
                          "requestingUser" : "",
                          "connectedTo" : "",
                          "pendingRequest" : false,
                          "latitude" : 0,
                          "longitude" : 0,
                          "isOnline" : false] as [String : Any]
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
    
    /// Request from view controller to log in to the database
    static func logInToDB(email: String,password: String,controller: UIViewController){
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if let err = error {
                controller.createAndDisplayAlert(withTitle: "Authorization error", body: err.localizedDescription)
                return
            }
            AppDelegate.shared.rootViewController.switchToMainScreen()
        }
    }
    
    /// Log out current user and return to login screen
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
    
    /// Fetch user for uid in database
    static func fetchUser(forUid uid: String,handler: @escaping((LocalUser) -> Void)) {
        usersRef.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let user = LocalUser()
                user.uid = uid
                user.name = dictionary["name"] as? String
                user.email = dictionary["email"] as? String
                handler(user)
            }
        }
    }
    
    /// Fetch all the users currently in the database
    static func fetchUsers(handler: @escaping (([LocalUser]) -> Void)) {
        var users = [LocalUser]()
        usersRef.observeSingleEvent(of: .value) { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                for child in dictionary.values {
                    if let userDictionary = child as? [String: AnyObject] {
                        let user = LocalUser()
                        user.name = userDictionary["name"] as? String
                        user.email = userDictionary["email"] as? String
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
    
    /// Add observer to current user for connection request
    static func observeConnectionRequests(handler: @escaping ((LocalUser) -> Void)) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let requestingUserRef = usersRef.child(uid).child("requestingUser")
        requestingUserRef.observe(.value) { (snapshot) in
            if let requestingUserUid = snapshot.value as? String {
                if !requestingUserUid.isEmpty {
                    FirebaseClient.fetchUser(forUid: requestingUserUid, handler: { (user) in
                        handler(user)
                    })
                }
            }
        }
    }
    
    static func observeUidValue(forKey key: String, handler: @escaping ((LocalUser) -> Void)) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = usersRef.child(uid).child(key)
        ref.observe(.value) { (snapshot) in
            if let observedUid = snapshot.value as? String {
                if !observedUid.isEmpty {
                    FirebaseClient.fetchUser(forUid: observedUid, handler: { (user) in
                        handler(user)
                    })
                }
            }
        }
    }
    
    static func observePending(handler: @escaping (() -> Void)) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = usersRef.child(uid)
        userRef.child("pendingRequest").observe(.value) { (snapshot) in
            if let isPending = snapshot.value as? Bool {
                if !isPending {
                    handler()
                    userRef.child("pendingRequest").removeAllObservers()
                }
            }
        }
    }
    
    /// See if user is connected to firebase
    static func checkOnline(handler: @escaping ((Bool) -> Void)) {
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value) { (snapshot) in
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let connected = snapshot.value as? Bool ?? false
            if connected {
                usersRef.child(uid).updateChildValues(["isOnline" : true])
            }else {
                usersRef.child(uid).updateChildValues(["isOnline" : false])
            }
            handler(connected)
        }
    }
    
    /// Check for connection initialized
    static func observeConnection(handler: @escaping((String) -> (Void))) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let connectedToRef = usersRef.child(uid).child("connectedTo")
        connectedToRef.observe(.value) { (snapshot) in
            if let connectedTo = snapshot.value as? String {
                if !connectedTo.isEmpty {
                    handler(connectedTo)
                }
            }
        }
    }
    
    static func fetchCoordinates(uid: String, handler: @escaping((Double?,Double?) -> (Void))) {
        let userRef = usersRef.child(uid)
        userRef.observeSingleEvent(of: .value) { (snapshot) in
            if let userDictionary = snapshot.value as? [String : Any] {
                let latitude = userDictionary["latitude"] as? Double
                let longitude = userDictionary["longitude"] as? Double
                handler(latitude,longitude)
            }
        }
    }
}
