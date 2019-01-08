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
    static func requestLineAndSteps(from start: CLLocationCoordinate2D,to end: CLLocationCoordinate2D, handler: @escaping(((line: MKPolyline?, steps: [MKRoute.Step]?, error: Error?)) -> Void)) {
        var result: (line: MKPolyline?, steps: [MKRoute.Step]?, error: Error?)
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        directionsRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        directionsRequest.transportType = .walking
        let directions = MKDirections(request: directionsRequest)
        directions.calculate { (response, error) in
            if error != nil { result.error = error }
            if let route = response?.routes[0] {
                result.line = route.polyline
                result.steps = route.steps
            }
            handler(result)
        }
    }
}
