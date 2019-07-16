//
//  LocationService.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 12/13/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import MapKit

class LocationService: NSObject {

    static let shared = LocationService()

    let locationManager = CLLocationManager()

    /// Set up behavior for MKMapView object
    static func setMapProperties(for map: MKMapView, in view: UIView, atCoordinate coordinate: CLLocationCoordinate2D, withCoordinateSpan span: Double) {
        map.frame = view.frame
        map.center = view.center
        map.showsUserLocation = true
        map.setCenter(coordinate, animated: true)
        map.setUserTrackingMode(.follow, animated: true)
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span))
        map.setRegion(region, animated: true)
    }
}
