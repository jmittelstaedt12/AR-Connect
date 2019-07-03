//
//  NavigationModel.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 12/13/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import MapKit

struct NavigationClient {

    /// Calls directions request for two locations and returns their polyline and the steps between them
    static func requestLineAndSteps(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, handler: @escaping (Result<MKPolyline, Error>) -> Void) {
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        directionsRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        directionsRequest.transportType = .walking
        let directions = MKDirections(request: directionsRequest)
        directions.calculate { (response, error) in
            if let error = error {
                handler(.failure(error))
            } else if let route = response?.routes[0], route.polyline.pointCount > 0 {
                handler(.success(route.polyline))
            }
        }
    }
}
