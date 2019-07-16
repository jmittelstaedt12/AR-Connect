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

final class MapViewController: UIViewController, MKMapViewDelegate, ControllerProtocol {

    // MARK: Properties

    typealias ViewModelType = MapViewModel

    var viewModel: ViewModelType!

    var currentLocation: CLLocation?
    let connectNotificationName = Notification.Name(NotificationConstants.requestResponseNotificationKey)
//    weak var delegate: LocationUpdateDelegate?
    var tripCoordinates: [CLLocationCoordinate2D] = []
    private var pathOverlay: MKPolyline?
    var headingAccuracy = [Double](repeating: 360.0, count: 4)
    var locationAccuracy = [Double](repeating: 100.0, count: 4)
    var recentLocationIndex = 0
    var willUpdateCurrentLocation = true
    private var meetupLocationVariable = BehaviorRelay<CLLocation?>(value: nil)
    private(set) var meetupLocationObservable: Observable<CLLocation>?
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

    let disposeBag = DisposeBag()
    func configure(with viewModel: ViewModelType) {

        viewModel.output.setCurrentLocationObservable
            .subscribe(onNext: { [weak self] coordinate in
                guard let self = self else { return }
                self.centerMap(atCoordinate: coordinate, withCoordinateSpan: 0.01)
            })
            .disposed(by: disposeBag)

        viewModel.output.setMapForConnectionObservable
            .subscribe(onNext: { [weak self] data in
                guard let self = self, data != nil else { return }
                self.pathOverlay = data!.userLine
                self.draw(polyline: data!.userLine, color: ColorConstants.primaryColor)
                if let line = data!.connectedUserLine {
                    self.draw(polyline: line, color: ColorConstants.secondaryColor)
                }
                self.map.setVisibleMapRect(data!.visibleMapRect, edgePadding: UIEdgeInsets(top: 80, left: 80, bottom: 80, right: 80), animated: true)
            })
            .disposed(by: disposeBag)

        viewModel.output.updatedCurrentLocationObservable
            .subscribe(onNext: { [weak self] location in
                self?.currentLocation = location
            })
            .disposed(by: disposeBag)

        viewModel.output.setTripCoordinatesObservable
            .subscribe(onNext: { [weak self] coordinates in
                self?.tripCoordinates = coordinates
            })
            .disposed(by: disposeBag)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view = map
        map.compassButton.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor,
                                      leading: view.safeAreaLayoutGuide.leadingAnchor,
                                      padding: UIEdgeInsets(top: 12, left: 12, bottom: 0, right: 0))
        map.delegate = self
        meetupLocationObservable = meetupLocationVariable.asObservable().ignoreNil().take(1)
    }

    // MARK: Updates to Map

    func draw(polyline line: MKPolyline, color: UIColor) {
        tempPolylineColor = color
        map.addOverlay(line)
    }

    func centerMap(atCoordinate coordinate: CLLocationCoordinate2D, withCoordinateSpan span: Double) {
        map.frame = view.frame
        map.center = view.center
        map.showsUserLocation = true
        map.setCenter(coordinate, animated: true)
        map.setUserTrackingMode(.follow, animated: true)
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span))
        map.setRegion(region, animated: true)
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        if overlay is MKPolyline {
            polylineRenderer.strokeColor = tempPolylineColor
            polylineRenderer.lineWidth = 5
        }
        return polylineRenderer
    }

    func resetMap() {
        for overlay in map.overlays {
            map.removeOverlay(overlay)
        }

        if let currentCoordinate = currentLocation?.coordinate {
            self.centerMap(atCoordinate: currentCoordinate, withCoordinateSpan: 0.01)
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

        setMeetupLocationButton?.edgeAnchors(leading: view.safeAreaLayoutGuide.leadingAnchor,
                                             bottom: view.safeAreaLayoutGuide.bottomAnchor,
                                             trailing: view.safeAreaLayoutGuide.trailingAnchor,
                                             padding: UIEdgeInsets(top: 0, left: 32, bottom: -12, right: -32))
        setMeetupLocationButton?.dimensionAnchors(height: 50)
    }

    @objc func didSetLocation() {
        locationSetterIcon?.removeFromSuperview()
        setMeetupLocationButton?.removeFromSuperview()

        locationSetterIcon = nil
        setMeetupLocationButton = nil

        meetupLocationVariable.accept(CLLocation(coordinate: map.centerCoordinate))
        meetupLocationVariable.accept(nil)
    }
}

extension MapViewController: MainViewMapDelegate {

    func centerAtLocation() {
        if let coordinate = currentLocation?.coordinate {
            self.centerMap(atCoordinate: coordinate, withCoordinateSpan: 0.01)
        }
    }

    func centerAtPath() {
        if let path = pathOverlay {
            map.setVisibleMapRect(MKMapRect(origin: path.boundingMapRect.origin,
                                            size: MKMapSize(width: path.boundingMapRect.size.width,
                                                            height: path.boundingMapRect.size.height)),
                                  edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40),
                                  animated: true)
        }
    }
}
