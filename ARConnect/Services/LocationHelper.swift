//
//  LocationModel.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/13/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import MapKit
import simd
import ARKit

struct LocationHelper {

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

    static func createIntermediaryCoordinates(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, withInterval interval: Double) -> [CLLocationCoordinate2D] {
        let bearing = calculateBearing(from: start, to: end)
        let totalDistance = Double(CLLocation(coordinate: start).distance(from: CLLocation(coordinate: end)))
        let points = [start] + Array(stride(from: interval, to: totalDistance - interval, by: interval)).map { calculateCoordinates(from: start, withBearing: bearing, andDistance: $0) }
        return points
    }

    /// From true north, determine angle between coordinate points using Haversine formula
    static func calculateBearing(from current: CLLocationCoordinate2D, to target: CLLocationCoordinate2D) -> Double {
//      From https://www.movable-type.co.uk/scripts/latlong.html :
        let lat1 = current.latitude.toRadians()
        let lon1 = current.longitude.toRadians()
        let lat2 = target.latitude.toRadians()
        let lon2 = target.longitude.toRadians()
        let dLon = lon2 - lon1
        let legA = sin(dLon) * cos(lat2)
        let legB = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        return atan2(legA, legB)
    }

    /// Do polar coordinate conversion to cartesian coordinates for ARKit grid system
    static func getARCoordinates(from current: CLLocation, to target: CLLocation) -> SCNVector3 {
        let transform = MatrixOperations.transformMatrix(for: matrix_identity_float4x4, originLocation: current, location: target)
        return SCNVector3(x: transform.columns.3.x, y: transform.columns.3.y, z: transform.columns.3.z)
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
