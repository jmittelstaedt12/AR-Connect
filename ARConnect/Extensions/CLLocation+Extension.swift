//
//  CLLocation+Extension.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 12/14/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import MapKit

extension CLLocation {
    convenience init(coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
