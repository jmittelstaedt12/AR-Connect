//
//  User.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/31/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

class LocalUser: NSObject {
    var name: String!
    var email: String!
    var uid: String!
    var profileUrl: URL?
    var profileImage: UIImage?
    var connectedUid: String?
    var isOnline: Bool!
}
