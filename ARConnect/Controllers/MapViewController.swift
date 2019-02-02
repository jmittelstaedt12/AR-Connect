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

    // MARK: Variables
    var currentLocation: CLLocation?
    let currentUser = Auth.auth().currentUser
    let locationService = LocationService()
    let connectNotificationName = Notification.Name(NotificationConstants.connectionNotificationKey)
    weak var delegate: LocationUpdateDelegate?
    var tripCoordinates: [CLLocationCoordinate2D] = []
    private var pathOverlay: MKOverlay?
    var headingAccuracy = [Double](repeating: 360.0, count: 4)
    var locationAccuracy = [Double](repeating: 100.0, count: 4)
    var recentLocationIndex = 0
    var bestReadingAccuracy = 30.1
    var willUpdateCurrentLocation = true

    let map: JMMKMapView = JMMKMapView()

    enum WorldAlignment {
        case gravity
        case gravityAndHeading
    }

    var shouldUseAlignment = WorldAlignment.gravity

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view = map
        map.compassButton.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor,
                                      padding: UIEdgeInsets(top: 12, left: 12, bottom: 0, right: 0))
        map.delegate = self
        setupLocationModel()
        NotificationCenter.default.addObserver(self, selector: #selector(setupMapForConnection(notification:)), name: connectNotificationName, object: nil)
    }

    private func setupLocationModel() {
        locationService.locationManager.delegate = self
        locationService.locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationService.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationService.locationManager.startUpdatingHeading()
            locationService.locationManager.startUpdatingLocation()
//            Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
//                self?.willUpdateCurrentLocation = true
//            }
        }

        guard let coordinate = locationService.locationManager.location?.coordinate else { return }
        LocationService.setMapProperties(for: map, in: super.view, atCoordinate: coordinate, withCoordinateSpan: 0.01)
    }

    private func setTestingConnection(location: CLLocation) {
//        let coordinate = CLLocationCoordinate2D(latitude: 40.68890581546788, longitude: -73.92998578213969)
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude+0.001,
                                                longitude: location.coordinate.longitude+0.001)
        NetworkRequests.directionsRequest(from: location.coordinate, to: coordinate) { [weak self] points in
            guard let self = self, points != nil else { return }
            self.tripCoordinates = points!
            var current = self.tripCoordinates.first!
            self.tripCoordinates = self.tripCoordinates.dropFirst().flatMap { step -> [CLLocationCoordinate2D] in
                let coordinates = LocationHelper.createIntermediaryCoordinates(from: current, to: step, withInterval: 5)
                current = step
                return coordinates
            }
            self.draw(polyline: MKPolyline(coordinates: self.tripCoordinates, count: self.tripCoordinates.count))
            self.delegate?.didReceiveTripSteps(self.tripCoordinates)
        }
//        NavigationClient.requestLineAndSteps(from: location.coordinate, to: coordinate, handler: { result in
//            if let error = result.error {
//                self.createAndDisplayAlert(withTitle: "Direction Request Error", body: error.localizedDescription)
//                return
//            }
//
//            guard let line = result.line else {
//                self.createAndDisplayAlert(withTitle: "Direction Request Error", body: "No routes found.")
//                return
//            }
//
////            self.pathOverlay = line
////            self.draw(polyline: line)
//
//            guard line.pointCount > 0 else { return }
//            for index in 0..<line.pointCount {
//                self.tripCoordinates.append(line.points()[index].coordinate)
//            }
//            var current = self.tripCoordinates.first!
//            self.tripCoordinates = self.tripCoordinates.dropFirst().flatMap { step -> [CLLocationCoordinate2D] in
//                let coordinates = LocationHelper.createIntermediaryCoordinates(from: current, to: step, withInterval: 5)
//                current = step
//                return coordinates
//            }
//            self.draw(polyline: MKPolyline(coordinates: self.tripCoordinates, count: self.tripCoordinates.count))
//            self.delegate?.didReceiveTripSteps(self.tripCoordinates)
//        })
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
                guard let line = result.line else {
                    self.createAndDisplayAlert(withTitle: "Direction Request Error", body: "No routes found.")
                    return
                }
                self.pathOverlay = line
                self.draw(polyline: line)
                guard line.pointCount > 0 else { return }
                for index in 0..<line.pointCount {
                    self.tripCoordinates.append(line.points()[index].coordinate)
                }
                var current = self.tripCoordinates.first!
                self.tripCoordinates = self.tripCoordinates.dropFirst().flatMap { step -> [CLLocationCoordinate2D] in
                    let coordinates = LocationHelper.createIntermediaryCoordinates(from: current, to: step, withInterval: 5)
                    current = step
                    return coordinates
                }
                self.delegate?.didReceiveTripSteps(self.tripCoordinates)

            })
        }
        //        let coordinate = CLLocationCoordinate2D(latitude: 40.68790581546788, longitude: -73.92998578213969)
    }

    func draw(polyline line: MKPolyline) {
        map.addOverlay(line)
        map.setVisibleMapRect(MKMapRect(origin: line.boundingMapRect.origin, size: MKMapSize(width: line.boundingMapRect.size.width,
                height: line.boundingMapRect.size.height)), edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: true)
    }

    func resetMap() {
        if let overlay = pathOverlay { map.removeOverlay(overlay) }

        if let currentCoordinate = currentLocation?.coordinate {
            LocationService.setMapProperties(for: map, in: super.view, atCoordinate: currentCoordinate, withCoordinateSpan: 0.01)
        }
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

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard let locValue = manager.location else { return }
        headingAccuracy[recentLocationIndex] = newHeading.headingAccuracy
        locationAccuracy[recentLocationIndex] = locValue.horizontalAccuracy
        recentLocationIndex = (recentLocationIndex + 1) % 4
        if headingAccuracy.contains(where: { $0 >= 0 && $0 <= 30 }) && locationAccuracy.contains(where: { $0 <= 30 }) {
            shouldUseAlignment = .gravityAndHeading
        } else {
            shouldUseAlignment = .gravity
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard willUpdateCurrentLocation, let locValue = manager.location, locValue.horizontalAccuracy < 30.0, let user = currentUser else { return }
        FirebaseClient.usersRef.child(user.uid).updateChildValues(["latitude": locValue.coordinate.latitude, "longitude": locValue.coordinate.longitude])

        if currentLocation == nil { setTestingConnection(location: locValue) }
        delegate?.didReceiveLocationUpdate(to: locValue)
        currentLocation = locValue
//        bestReadingAccuracy = locValue.horizontalAccuracy
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
