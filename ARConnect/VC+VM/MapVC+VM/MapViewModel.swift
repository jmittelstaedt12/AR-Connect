//
//  MapViewModel.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/13/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Foundation
import MapKit
import RxSwift

class MapViewModel: NSObject, ViewModelProtocol {

    typealias MapConnectionData = (userLine: MKPolyline, connectedUserLine: MKPolyline?, visibleMapRect: MKMapRect)?

    let uid: String
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    let connectNotificationName = Notification.Name(NotificationConstants.requestResponseNotificationKey)

    weak var delegate: LocationUpdateDelegate? {
        didSet {
            locationManager.stopUpdatingHeading()
        }
    }
    
    var tripCoordinates: [CLLocationCoordinate2D] = []
    private var pathOverlay: MKPolyline?
    var headingAccuracy = [Double](repeating: 360.0, count: 4)
    var locationAccuracy = [Double](repeating: 100.0, count: 4)
    var recentLocationIndex = 0
    var willUpdateCurrentLocation = true
    private var tempPolylineColor: UIColor?

    enum WorldAlignment {
        case gravity
        case gravityAndHeading
    }

    var shouldUseAlignment = WorldAlignment.gravity

    struct Input {

    }

    struct Output {
        let setCurrentLocationObservable: Observable<CLLocationCoordinate2D>
        let setMapForConnectionObservable: Observable<MapConnectionData>
        let updatedCurrentLocationObservable: Observable<CLLocation>
    }

    let input: Input
    let output: Output

    private let setCurrentLocationSubject = PublishSubject<CLLocationCoordinate2D>()
    private let setMapForConnectionSubject = PublishSubject<MapConnectionData>()
    private let updatedCurrentLocationSubject = PublishSubject<CLLocation>()

    init(uid: String) {
        self.uid = uid
        input = Input()
        output = Output(setCurrentLocationObservable: setCurrentLocationSubject.asObserver(),
                        setMapForConnectionObservable: setMapForConnectionSubject.asObserver(),
                        updatedCurrentLocationObservable: updatedCurrentLocationSubject.asObserver())
        super.init()
        setupLocationModel()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(setupMapForConnection(notification:)),
                                               name: connectNotificationName,
                                               object: nil)
    }

    private func setupLocationModel() {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingHeading()
            locationManager.startUpdatingLocation()
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
                self?.willUpdateCurrentLocation = true
            }
        }

        guard let coordinate = locationManager.location?.coordinate else { return }
        setCurrentLocationSubject.onNext(coordinate)
    }

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

    @objc private func setupMapForConnection(notification: NSNotification) {
        guard let didConnect = notification.userInfo?["didConnect"] as? Bool,
            didConnect, let currentLocation = currentLocation else { return }
        let connectedUid = notification.userInfo?["uid"] as! String
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
                return
            }
            userLine = result.line
        }

        group.enter()
        FirebaseClient.fetchCoordinates(uid: connectedUid) { (latitude, longitude) -> Void in
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
                    return
                }
                connectedUserLine = result.line
            }
        }

        group.notify(queue: .main) { [unowned self] in
            guard let userPath = userLine else {
                self.setMapForConnectionSubject.onNext(nil)
                return
            }
            self.pathOverlay = userPath
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
                let visibleRegion = connectedUserPath.boundingMapRect.union(self.pathOverlay!.boundingMapRect)
                self.setMapForConnectionSubject.onNext((userLine: userPath, connectedUserLine: connectedUserPath, visibleMapRect: visibleRegion))
            } else {
                self.setMapForConnectionSubject.onNext((userLine: userPath, connectedUserLine: nil, visibleMapRect: userPath.boundingMapRect))
            }
            //            connectedUserLine = MKPolyline(coordinates:
            //                                            UnsafeMutablePointer(mutating: self.tripCoordinates.map { CLLocationCoordinate2D(latitude: $0.latitude + 0.01,
            //                                                                                                                             longitude: $0.longitude + 0.01) }),
            //                                                                 count: self.tripCoordinates.count)
        }
    }

    deinit {
        locationManager.stopUpdatingLocation()
    }
}

// MARK: CLLocationManagerDelegate
extension MapViewModel: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard let locValue = manager.location else { return }
        headingAccuracy[recentLocationIndex] = newHeading.headingAccuracy
        locationAccuracy[recentLocationIndex] = locValue.horizontalAccuracy
        recentLocationIndex = (recentLocationIndex + 1) % 4
        if headingAccuracy.contains(where: { $0 >= 0 && $0 <= 30 }) {
            shouldUseAlignment = .gravityAndHeading
        } else {
            shouldUseAlignment = .gravity
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard willUpdateCurrentLocation, let locValue = manager.location else { return }
        FirebaseClient.usersRef.child(uid)
            .updateChildValues(["latitude": locValue.coordinate.latitude,
                                "longitude": locValue.coordinate.longitude])

        //        if currentLocation == nil { setTestingConnection(location: locValue) }
        delegate?.didReceiveLocationUpdate(to: locValue)
        updatedCurrentLocationSubject.onNext(locValue)
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

protocol LocationUpdateDelegate: AnyObject {
    func didReceiveLocationUpdate(to location: CLLocation)
    func didReceiveTripSteps(_ steps: [CLLocationCoordinate2D])
    func failedToUpdateLocation()
}
