//
//  LocationModel.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/13/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class LocationModel {
    
    let locationManager = CLLocationManager()

    func setupMap(map: MKMapView, view: UIView) {
        map.frame = view.frame
        map.center = view.center
        map.showsUserLocation = true
        if let coordinate = locationManager.location?.coordinate {
            map.setCenter(coordinate, animated: true)
            map.setUserTrackingMode(.follow, animated: true)
            let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            map.setRegion(region, animated: true)
        }
    }
}
