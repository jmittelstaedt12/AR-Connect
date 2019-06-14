//
//  User.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/31/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

struct RegisterUser {
    var firstName: String!
    var lastName: String!
    var email: String!
    var password: String!
    var pngData: Data?
}

struct LocalUser {
    var name: String!
    var email: String!
    var uid: String!
    var isOnline: Bool!
    var profileUrl: URL?
    var profileImageData: Data?
    var connectedUid: String?

    init(name: String = "", email: String = "", uid: String = "", isOnline: Bool = false) {
        self.name = name
        self.email = email
        self.uid = uid
        self.isOnline = isOnline
    }
}

extension LocalUser: Equatable {
    static func ==(lhs: LocalUser, rhs: LocalUser) -> Bool {
        return lhs.name == rhs.name && lhs.email == rhs.email && lhs.uid == rhs.uid && lhs.connectedUid == rhs.connectedUid &&
            lhs.profileUrl == rhs.profileUrl && lhs.profileImageData == rhs.profileImageData
    }
}
