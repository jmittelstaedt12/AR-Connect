//
//  MapViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 11/21/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class MapViewController: UIViewController, CLLocationManagerDelegate {
    
    var currentLocation: CLLocationCoordinate2D?

    let currentUser = Auth.auth().currentUser
    let locationModel = LocationModel()
    let connectNotificationName = Notification.Name(connectionNotificationKey)
    
    let map : MKMapView = {
        let map = MKMapView()
        map.mapType = .standard
        map.isZoomEnabled = true
        map.isScrollEnabled = true
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view = map
        locationModel.locationManager.delegate = self
        locationModel.locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationModel.locationManager.delegate = self
            locationModel.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationModel.locationManager.startUpdatingLocation()
        }
        locationModel.setMapProperties(for: self.view as! MKMapView, in: super.view)
        createObserver()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate, let user = currentUser else { return }
        currentLocation = locValue
        FirebaseClient.usersRef.child(user.uid).updateChildValues(["latitude" : locValue.latitude, "longitude" : locValue.longitude])
    }
    
    private func createObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(setupMapForConnection(notification:)), name: connectNotificationName, object: nil)
    }
    
    @objc private func setupMapForConnection(notification: NSNotification) {
        guard let userInfo = notification.userInfo else {
            print("No user attached")
            return
        }
        let user = userInfo["user"] as! LocalUser
        
        #warning("UNCOMMENT CODE AND DELETE SECTION IN FINAL BUILD")
        let coordinate = CLLocationCoordinate2D(latitude: 40.9, longitude: -73.9)
//        FirebaseClient.fetchCoordinates(uid: user.uid!) { (latitude, longitude) -> (Void) in
//            guard let lat = latitude, let lon = longitude else {
//                print("coordinates not available")
//                return
//            }
//            let annotation = MKPointAnnotation()
//            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
//            annotation.coordinate = coordinate
//            self.map.addAnnotation(annotation)
//        }
        guard let locVal = currentLocation else { return }
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: locVal))
        directionsRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        directionsRequest.transportType = .walking
        let directions = MKDirections(request: directionsRequest)
        directions.calculate { (response, error) in
            if let routes = response?.routes {
                
            } else if let err = error {
                
            }
        }
    }
    
    private func plotPolyline(route: MKRoute) {
        
    }
}
