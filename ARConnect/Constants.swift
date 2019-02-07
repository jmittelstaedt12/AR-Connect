//
//  constants.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 11/21/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

struct ColorConstants {
    static let primaryColor = UIColor(red: 225, green: 65, blue: 100)
    static let secondaryColor = UIColor(red: 114, green: 1, blue: 48)
}

struct LocationConstants {
    static let radius = 6.371 * 1E6
}

struct NotificationConstants {
    static let requestResponseNotificationKey = "jacobm.ARConnect.didConnectKey"
}
