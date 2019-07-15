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
    let auth: JMAuth!
    let usersRef: DatabaseReference!

    enum Functionality {
        case network, mock
    }

    init(functionality: Functionality, auth: JMAuth? = nil, usersRef: DatabaseReference? = nil) {
        switch functionality {
        case .network:
            self.auth = JMAuth()
            self.usersRef = Database.database().reference().child("Users")
        case .mock:
            if let auth = auth {
                self.auth = auth
            } else {
                let user = LocalUser(name: "Jacob Mittel", email: "jacob@gmail.com", uid: "S1HrJFwrwUalb37PzVHny6B5qry2")
                self.auth = JMAuth(mock: true, willFail: false, mockUser: user)
            }

            if let usersRef = usersRef {
                self.usersRef = usersRef
            } else {
                let mockDatabase =
                    ["S1HrJFwrwUalb37PzVHny6B5qry2":
                        ["connectedTo": "",
                         "email": "jacob@gmail.com",
                         "isConnected": false,
                         "isOnline": true,
                         "isPending": false,
                         "latitude": 40.68776992071587,
                         "longitude": -73.92892530229798,
                         "name": "Jacob Mittel",
                         "pendingRequest": false,
                         "profileImageUrl": "https://firebasestorage.googleapis.com/v0/b/ar-connect.appspot.com/o/FF66F260-8C9B-4AC2-A604-B0BA9D2ED8D7.png?alt=media&token=6220e672-22b5-4abb-9fb3-756c0e3ef8ff",
                         "requestingUser":
                            ["latitude": 0.0,
                             "longitude": 0.0,
                             "uid": ""
                            ]
                        ]
                ]
                DatabaseeReferenceMock.initializeDatabase(mockDatabaseDictionary: mockDatabase)
                self.usersRef = DatabaseeReferenceMock(pointsTo: [])
            }
        }
    }
}
