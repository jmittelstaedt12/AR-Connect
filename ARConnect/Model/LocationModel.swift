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

    // Set up behavior for MKMapView object
    func setMapProperties(for map: MKMapView,in view: UIView) {
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
    
    // From true north, determine angle between coordinate points using Haversine formula
    class func calculateBearing(from current: CLLocationCoordinate2D,to target: CLLocationCoordinate2D) -> Double {
        let a = sin(target.longitude.toRadians() - current.longitude.toRadians()) * cos(target.latitude.toRadians())
        let b = cos(current.latitude.toRadians()) * sin(target.latitude.toRadians()) - sin(current.latitude.toRadians()) * cos(target.latitude.toRadians()) * cos(current.longitude.toRadians() - target.longitude.toRadians())
        return atan2(a, b)
    }
    
    // Do polar coordinate conversion to cartesian coordinates for ARKit grid system
    class func getARCoordinates(from current: CLLocation,to target: CLLocation) -> (Double, Double){
        let bearing = calculateBearing(from: current.coordinate, to: target.coordinate)
        let distance = current.distance(from: target)
        return (distance*cos(bearing),distance*sin(bearing))
    }
}

extension Double {
    func toRadians() -> Double {
        return self * .pi / 180.0
    }
    
    func toDegrees() -> Double {
        return self * 180.0 / .pi
    }
}
