//
//  Firebase.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/27/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Foundation
import Firebase

struct Firebase {
    let auth: JMAuth
    let usersRef: DatabaseReference
    init(auth: JMAuth = JMAuth(), usersRef: DatabaseReference = Database.database().reference().child("Users")) {
        self.auth = auth
        self.usersRef = usersRef
    }
}
