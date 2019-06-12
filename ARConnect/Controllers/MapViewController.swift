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
    func failedToUpdateLocation()
}

final class MapViewController: UIViewController, MKMapViewDelegate {

    // MARK: Variables

    var currentLocation: CLLocation?
    let currentUser = Auth.auth().currentUser
    let locationService = LocationService()
    let connectNotificationName = Notification.Name(NotificationConstants.requestResponseNotificationKey)
    weak var delegate: LocationUpdateDelegate?
    var tripCoordinates: [CLLocationCoordinate2D] = []
    private var pathOverlay: MKPolyline?
    var headingAccuracy = [Double](repeating: 360.0, count: 4)
    var locationAccuracy = [Double](repeating: 100.0, count: 4)
    var recentLocationIndex = 0
    var willUpdateCurrentLocation = true
    private var meetupLocationVariable = BehaviorRelay<CLLocationCoordinate2D?>(value: nil)
    private(set) var meetupLocationObservable: Observable<CLLocationCoordinate2D>?
    private var tempPolylineColor: UIColor?
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
            btn.backgroundColor = ColorConstants.primaryColor
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.lineBreakMode = .byWordWrapping
            btn.titleLabel?.textAlignment = .center
            btn.setTitle("Set Meetup Location", for: .normal)
            btn.layer.cornerRadius = 25
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

//    private func setTestingConnection(location: CLLocation) {
//        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude+0.001,
//                                                longitude: location.coordinate.longitude+0.001)
//        NetworkRequests.directionsRequest(from: location.coordinate, to: coordinate) { [weak self] points in
//            guard let self = self, points != nil else { return }
//            self.tripCoordinates = points!
//            var current = self.tripCoordinates.first!
//            self.tripCoordinates = self.tripCoordinates.dropFirst().flatMap { step -> [CLLocationCoordinate2D] in
//                let coordinates = LocationHelper.createIntermediaryCoordinates(from: current, to: step, withInterval: 5)
//                current = step
//                return coordinates
//            }
//            self.pathOverlay = MKPolyline(coordinates: self.tripCoordinates, count: self.tripCoordinates.count)
//            DispatchQueue.main.async {
//                self.draw(polyline: self.pathOverlay!, color: ColorConstants.primaryColor)
//            }
//            self.delegate?.didReceiveTripSteps(self.tripCoordinates)
//        }
//    }

    @objc func centerAtLocation() {
        if let coordinate = currentLocation?.coordinate {
            LocationService.setMapProperties(for: map, in: super.view, atCoordinate: coordinate, withCoordinateSpan: 0.003)
        }
    }

    @objc func centerAtPath() {
        if let path = pathOverlay {
            map.setVisibleMapRect(MKMapRect(origin: path.boundingMapRect.origin,
                                            size: MKMapSize(width: path.boundingMapRect.size.width,
                                                            height: path.boundingMapRect.size.height)),
                                            edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: true)
        }
    }

    @objc private func setupMapForConnection(notification: NSNotification) {
        guard let didConnect = notification.userInfo?["didConnect"] as? Bool,
            didConnect, let currentLocation = currentLocation else { return }
        let user = notification.userInfo?["user"] as! LocalUser
        let meetupLocation = notification.userInfo?["meetupLocation"] as! CLLocation

        let group = DispatchGroup()
        var userLine: MKPolyline?
        var connectedUserLine: MKPolyline?
        group.enter()
        NavigationClient.requestLineAndSteps(from: currentLocation.coordinate, to: meetupLocation.coordinate) { result in
            defer {
                group.leave()
            }
            if let error = result.error {
                self.createAndDisplayAlert(withTitle: "Direction Request Error", body: error.localizedDescription)
                return
            }
            userLine = result.line
        }

        group.enter()
        FirebaseClient.fetchCoordinates(uid: user.uid!) { (latitude, longitude) -> Void in
            guard let lat = latitude, let lon = longitude else {
                group.leave()
                return
            }
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            NavigationClient.requestLineAndSteps(from: coordinate, to: meetupLocation.coordinate) { result in
                defer {
                    group.leave()
                }
                if let error = result.error {
                    self.createAndDisplayAlert(withTitle: "Direction Request Error", body: error.localizedDescription)
                    return
                }
                connectedUserLine = result.line
            }
        }

        group.notify(queue: .main) { [unowned self] in
            guard let userPath = userLine else { return }
            self.pathOverlay = userPath
            self.draw(polyline: userPath, color: ColorConstants.primaryColor)
            for index in 0..<userPath.pointCount {
                self.tripCoordinates.append(userPath.points()[index].coordinate)
            }
            var current = self.tripCoordinates.first!
            self.tripCoordinates = self.tripCoordinates.dropFirst().flatMap { step -> [CLLocationCoordinate2D] in
                let coordinates = LocationHelper.createIntermediaryCoordinates(from: current, to: step, withInterval: 5)
                current = step
                return coordinates
            }
            self.delegate?.didReceiveTripSteps(self.tripCoordinates)
            if let connectedUserPath = connectedUserLine {
                self.draw(polyline: connectedUserPath, color: ColorConstants.secondaryColor)
                self.map.setVisibleMapRect(connectedUserPath.boundingMapRect.union(self.pathOverlay!.boundingMapRect), animated: true)
            } else {
                self.map.setVisibleMapRect(self.pathOverlay!.boundingMapRect, animated: true)
            }
//            connectedUserLine = MKPolyline(coordinates:
//                                            UnsafeMutablePointer(mutating: self.tripCoordinates.map { CLLocationCoordinate2D(latitude: $0.latitude + 0.01,
//                                                                                                                             longitude: $0.longitude + 0.01) }),
//                                                                 count: self.tripCoordinates.count)
        }
//        NetworkRequests.directionsRequest(from: currentLocation.coordinate, to: meetupLocation) { [weak self] points in
//            guard let self = self, points != nil else { return }
//            self.tripCoordinates = points!
//            var current = self.tripCoordinates.first!
//            self.tripCoordinates = self.tripCoordinates.dropFirst().flatMap { step -> [CLLocationCoordinate2D] in
//                let coordinates = LocationHelper.createIntermediaryCoordinates(from: current, to: step, withInterval: 5)
//                current = step
//                return coordinates
//            }
//            self.pathOverlay = MKPolyline(coordinates: self.tripCoordinates, count: self.tripCoordinates.count)
//            DispatchQueue.main.async {
//                self.draw(polyline: self.pathOverlay!, color: ColorConstants.primaryColor)
//            }
//            self.delegate?.didReceiveTripSteps(self.tripCoordinates)
//        }

//        FirebaseClient.fetchCoordinates(uid: user.uid!) { (latitude, longitude) -> Void in
//            guard let lat = latitude, let lon = longitude else {
//                print("coordinates not available")
//                return
//            }
//            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
//            NetworkRequests.directionsRequest(from: coordinate, to: meetupLocation) { [weak self] points in
//                guard let self = self, let points = points, !points.isEmpty else { return }
//                self.tripCoordinates = points
//                var current = points.first!
//                let friendCoordinates = points.dropFirst().flatMap { step -> [CLLocationCoordinate2D] in
//                    let coordinates = LocationHelper.createIntermediaryCoordinates(from: current, to: step, withInterval: 5)
//                    current = step
//                    return coordinates
//                }
//                let friendPath = MKPolyline(coordinates: friendCoordinates, count: friendCoordinates.count)
//                DispatchQueue.main.async {
//                    self.draw(polyline: friendPath, color: ColorConstants.secondaryColor)
//                }
//            }
//        }
    }

    // MARK: Updates to Map

    func draw(polyline line: MKPolyline, color: UIColor) {
        tempPolylineColor = color
        map.addOverlay(line)
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        if overlay is MKPolyline {
            polylineRenderer.strokeColor =
                tempPolylineColor
            polylineRenderer.lineWidth = 5
        }
        return polylineRenderer
    }

    func resetMap() {
        for overlay in map.overlays {
            map.removeOverlay(overlay)
        }

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

        setMeetupLocationButton?.edgeAnchors(leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor,
                                             trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: UIEdgeInsets(top: 0, left: 32, bottom: -12, right: -32))
        setMeetupLocationButton?.dimensionAnchors(height: 50)
    }

    @objc func didSetLocation() {
        locationSetterIcon?.removeFromSuperview()
        setMeetupLocationButton?.removeFromSuperview()

        locationSetterIcon = nil
        setMeetupLocationButton = nil

        meetupLocationVariable.accept(map.centerCoordinate)
        meetupLocationVariable.accept(nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {

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

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            setupLocationModel()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.failedToUpdateLocation()
    }
}
