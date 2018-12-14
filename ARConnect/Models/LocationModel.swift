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

struct LocationModel {
    
    static func calculateCoordinates(from start: CLLocationCoordinate2D, withBearing bearing: Double, andDistance distance: Double) -> CLLocationCoordinate2D {
//      From https://www.movable-type.co.uk/scripts/latlong.html :
        let angularDistanceLat = distance / LocationConstants.metersPerRadiansLatitude
        let angularDistanecLon = distance / LocationConstants.metersPerRadiansLongitude
        let lat1 = start.latitude.toRadians()
        let lon1 = start.longitude.toRadians()
        let lat2 = asin(sin(lat1) * cos(angularDistanceLat) + cos(lat1) * sin(angularDistanceLat) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(angularDistanecLon) * cos(lat1), cos(angularDistanecLon) - sin(lat1) * sin(lat2))
        return CLLocationCoordinate2D(latitude: lat2.toDegrees(), longitude: lon2.toDegrees())
    }
    
    static func createIntermediaryCoordinates(from start: CLLocation,to end: CLLocation, withInterval interval: Double) -> [CLLocationCoordinate2D] {
        var points = [CLLocationCoordinate2D]()
        let bearing = calculateBearing(from: start.coordinate, to: end.coordinate)
        let totalDistance = Double(start.distance(from: end))
        var intermediaryDistance = interval
        while totalDistance - intermediaryDistance > interval {
            intermediaryDistance += interval
            let coordinate = calculateCoordinates(from: start.coordinate, withBearing: bearing, andDistance: intermediaryDistance)
            points.append(coordinate)
        }
        return points
    }
    
    /// From true north, determine angle between coordinate points using Haversine formula
    static func calculateBearing(from current: CLLocationCoordinate2D,to target: CLLocationCoordinate2D) -> Double {
//      From https://www.movable-type.co.uk/scripts/latlong.html :
        let lat1 = current.latitude.toRadians()
        let lon1 = current.longitude.toRadians()
        let lat2 = target.latitude.toRadians()
        let lon2 = target.longitude.toRadians()
        let dLon = lon2 - lon1
        let a = sin(dLon) * cos(lat2)
        let b = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        return atan2(a, b)
    }
    
    /// Do polar coordinate conversion to cartesian coordinates for ARKit grid system
    static func getARCoordinates(from current: CLLocation,to target: CLLocation) -> (Double, Double) {
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
