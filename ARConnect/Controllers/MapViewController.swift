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

protocol LocationUpdateDelegate: AnyObject {
    func didReceiveLocationUpdate(to location: CLLocation)
    func didReceiveTripSteps(_ steps: [CLLocationCoordinate2D])
}

final class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    var currentLocation: CLLocation?
    let currentUser = Auth.auth().currentUser
    let locationService = LocationService()
    let connectNotificationName = Notification.Name(NotificationConstants.connectionNotificationKey)
    weak var delegate: LocationUpdateDelegate?
    var tripCoordinates: [CLLocationCoordinate2D] = []
    private var pathOverlay: MKOverlay?

    let map: MKMapView = {
        let map = MKMapView()
        map.mapType = .standard
        map.isZoomEnabled = true
        map.isScrollEnabled = true
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view = map
        map.delegate = self
        setupLocationModel()
        NotificationCenter.default.addObserver(self, selector: #selector(setupMapForConnection(notification:)), name: connectNotificationName, object: nil)
    }

    private func setupLocationModel() {
        locationService.locationManager.delegate = self
        locationService.locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationService.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationService.locationManager.startUpdatingLocation()
        }
        locationService.setMapProperties(for: map, in: super.view)
    }

    @objc private func setupMapForConnection(notification: NSNotification) {
        guard let currentLocation = currentLocation else { return }
        guard let userInfo = notification.userInfo else {
            print("No user attached")
            return
        }
        let user = userInfo["user"] as! LocalUser
        FirebaseClient.fetchCoordinates(uid: user.uid!) { (latitude, longitude) -> Void in
            guard let lat = latitude, let lon = longitude else {
                print("coordinates not available")
                return
            }
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            print(currentLocation.coordinate, coordinate)
            NavigationClient.requestLineAndSteps(from: currentLocation.coordinate, to: coordinate, handler: { result in
                if let error = result.error {
                    self.createAndDisplayAlert(withTitle: "Direction Request Error", body: error.localizedDescription)
                    return
                }
                guard let line = result.line, let steps = result.steps else {
                    self.createAndDisplayAlert(withTitle: "Direction Request Error", body: "No routes found.")
                    return
                }
                self.pathOverlay = line
                self.draw(polyline: line)
                self.tripCoordinates.append(contentsOf: steps.map { $0.polyline.coordinate })
                self.delegate?.didReceiveTripSteps(self.tripCoordinates)

            })
        }
        //        let coordinate = CLLocationCoordinate2D(latitude: 40.68790581546788, longitude: -73.92998578213969)
    }

    func draw(polyline line: MKPolyline) {
        map.addOverlay(line)
        map.setVisibleMapRect(MKMapRect(origin: line.boundingMapRect.origin, size: MKMapSize(width: line.boundingMapRect.size.width, height: line.boundingMapRect.size.height)), edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: true)
    }

    func resetMap() {
        if let overlay = pathOverlay { map.removeOverlay(overlay) }
        if let currentCoordinate = currentLocation?.coordinate { map.setCenter(currentCoordinate, animated: true) }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        if overlay is MKPolyline {
            polylineRenderer.strokeColor =
                UIColor.blue.withAlphaComponent(0.75)
            polylineRenderer.lineWidth = 5
        }
        return polylineRenderer
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue = manager.location, let user = currentUser else { return }
        currentLocation = locValue
        delegate?.didReceiveLocationUpdate(to: locValue)
        FirebaseClient.usersRef.child(user.uid).updateChildValues(["latitude": locValue.coordinate.latitude, "longitude": locValue.coordinate.longitude])
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
