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
import RxSwift
import RxCocoa

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
    private var pathOverlay: MKPolyline?
    var headingAccuracy = [Double](repeating: 360.0, count: 4)
    var locationAccuracy = [Double](repeating: 100.0, count: 4)
    var recentLocationIndex = 0
    var willUpdateCurrentLocation = true
    private var meetupLocationVariable = BehaviorRelay<CLLocationCoordinate2D?>(value: nil)
    private(set) var meetupLocationObservable: Observable<CLLocationCoordinate2D>?

    let map: JMMKMapView = JMMKMapView()

    enum WorldAlignment {
        case gravity
        case gravityAndHeading
    }

    var shouldUseAlignment = WorldAlignment.gravity

    var locationSetterIcon: UIImageView? {
        willSet {
            guard let view = newValue else { return }
            view.backgroundColor = .red
            view.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    var setMeetupLocationButton: UIButton? {
        willSet {
            guard let btn = newValue else { return }
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.backgroundColor = .white
            btn.setTitle("Set Meetup Location", for: .normal)
            btn.layer.cornerRadius = 5
            btn.addTarget(self, action: #selector(didSetLocation), for: .touchUpInside)
        }
    }

    // MARK: Initial Setup

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view = map
        map.compassButton.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor,
                                      padding: UIEdgeInsets(top: 12, left: 12, bottom: 0, right: 0))
        map.delegate = self
        setupLocationModel()
        NotificationCenter.default.addObserver(self, selector: #selector(setupMapForConnection(notification:)), name: connectNotificationName, object: nil)
        meetupLocationObservable = meetupLocationVariable.asObservable().filter { $0 != nil }.map { return $0! }.take(1)
    }

    private func setupLocationModel() {
        locationService.locationManager.delegate = self
        locationService.locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationService.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationService.locationManager.startUpdatingHeading()
            locationService.locationManager.startUpdatingLocation()
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
                self?.willUpdateCurrentLocation = true
            }
        }

        guard let coordinate = locationService.locationManager.location?.coordinate else { return }
        LocationService.setMapProperties(for: map, in: super.view, atCoordinate: coordinate, withCoordinateSpan: 0.01)
    }

    // MARK: Directions Requests

    private func setTestingConnection(location: CLLocation) {
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
            self.pathOverlay = MKPolyline(coordinates: self.tripCoordinates, count: self.tripCoordinates.count)
            DispatchQueue.main.async {
                self.draw(polyline: self.pathOverlay!)
            }
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
            NetworkRequests.directionsRequest(from: currentLocation.coordinate, to: coordinate) { [weak self] points in
                guard let self = self, points != nil else { return }
                self.tripCoordinates = points!
                var current = self.tripCoordinates.first!
                self.tripCoordinates = self.tripCoordinates.dropFirst().flatMap { step -> [CLLocationCoordinate2D] in
                    let coordinates = LocationHelper.createIntermediaryCoordinates(from: current, to: step, withInterval: 5)
                    current = step
                    return coordinates
                }
                self.pathOverlay = MKPolyline(coordinates: self.tripCoordinates, count: self.tripCoordinates.count)
                DispatchQueue.main.async {
                    self.draw(polyline: self.pathOverlay!)
                }
                self.delegate?.didReceiveTripSteps(self.tripCoordinates)
            }

//            NavigationClient.requestLineAndSteps(from: currentLocation.coordinate, to: coordinate) { result in
//                if let error = result.error {
//                    self.createAndDisplayAlert(withTitle: "Direction Request Error", body: error.localizedDescription)
//                    return
//                }
//                guard let line = result.line else {
//                    self.createAndDisplayAlert(withTitle: "Direction Request Error", body: "No routes found.")
//                    return
//                }
//                self.pathOverlay = line
//                self.draw(polyline: line)
//                guard line.pointCount > 0 else { return }
//                for index in 0..<line.pointCount {
//                    self.tripCoordinates.append(line.points()[index].coordinate)
//                }
//                var current = self.tripCoordinates.first!
//                self.tripCoordinates = self.tripCoordinates.dropFirst().flatMap { step -> [CLLocationCoordinate2D] in
//                    let coordinates = LocationHelper.createIntermediaryCoordinates(from: current, to: step, withInterval: 5)
//                    current = step
//                    return coordinates
//                }
//                self.delegate?.didReceiveTripSteps(self.tripCoordinates)
//
//            }
        }
    }

    // MARK: Updates to Map

    func draw(polyline line: MKPolyline) {
        map.addOverlay(line)
        map.setVisibleMapRect(MKMapRect(origin: line.boundingMapRect.origin, size: MKMapSize(width: line.boundingMapRect.size.width,
                height: line.boundingMapRect.size.height)), edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: true)
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

    func resetMap() {
        if let overlay = pathOverlay { map.removeOverlay(overlay) }

        if let currentCoordinate = currentLocation?.coordinate {
            LocationService.setMapProperties(for: map, in: super.view, atCoordinate: currentCoordinate, withCoordinateSpan: 0.01)
        }
    }

    // MARK: Setting Meetup Location

    func willSetLocationMarker() {
        locationSetterIcon = UIImageView()
        setMeetupLocationButton = UIButton()

        view.addSubview(locationSetterIcon!)
        view.addSubview(setMeetupLocationButton!)

        locationSetterIcon?.centerAnchors(centerX: view.centerXAnchor, centerY: view.centerYAnchor)
        locationSetterIcon?.dimensionAnchors(height: 25, width: 25)

        setMeetupLocationButton?.edgeAnchors(bottom: view.safeAreaLayoutGuide.bottomAnchor, padding: UIEdgeInsets(top: 0, left: 0, bottom: -12, right: 0))
        setMeetupLocationButton?.centerAnchors(centerX: view.centerXAnchor)
        setMeetupLocationButton?.dimensionAnchors(height: 40, width: 100)
    }

    @objc func didSetLocation() {
        locationSetterIcon?.removeFromSuperview()
        setMeetupLocationButton?.removeFromSuperview()

        locationSetterIcon = nil
        setMeetupLocationButton = nil

        meetupLocationVariable.accept(map.centerCoordinate)
    }

    // MARK: CLLocationManagerDelegate

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
        guard willUpdateCurrentLocation, let locValue = manager.location, let user = currentUser else { return }
        FirebaseClient.usersRef.child(user.uid).updateChildValues(["latitude": locValue.coordinate.latitude, "longitude": locValue.coordinate.longitude])

//        if currentLocation == nil { setTestingConnection(location: locValue) }
        delegate?.didReceiveLocationUpdate(to: locValue)
        currentLocation = locValue
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
