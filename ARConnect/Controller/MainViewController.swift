//
//  MapViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/9/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class MainViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate{
    
    var locationModel = LocationModel()

    let mapView: MKMapView = {
        let map = MKMapView()
        map.mapType = .standard
        map.isZoomEnabled = true
        map.isScrollEnabled = true
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()
    
    let searchTextField: UITextField = {
        let tf = UITextField()
        tf.backgroundColor = .white
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.layer.borderWidth = 2
        tf.layer.borderColor = UIColor.black.cgColor
        tf.layer.cornerRadius = 5
        return tf
    }()
    
    let startConnectSessionButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Start", for: .normal)
        btn.setTitleColor(UIColor.black, for: .normal)
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 5
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(startARSession), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationModel.locationManager.delegate = self
        locationModel.locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationModel.locationManager.delegate = self
            locationModel.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationModel.locationManager.startUpdatingLocation()
        }
        
        title = "AR Connect"
        let logoutButton = UIBarButtonItem(title: "Log Out", style: .plain, target: self, action: #selector(FBClient.logoutOfDB))
        navigationItem.setLeftBarButton(logoutButton, animated: true)
        
        view.addSubview(mapView)
        view.addSubview(searchTextField)
        view.addSubview(startConnectSessionButton)
        setupMap()
        setupSearchTextField()
        setupStartConnectSessionButton()
        
        searchTextField.delegate = self
        hideKeyboardWhenTappedAround()
    }
    
    // Setup auto layout anchors for map view
    private func setupMap() {
        locationModel.setupMap(map: mapView, view: view)
        mapView.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor)
    }
    
    // Setup auto layout anchors for search text field
    private func setupSearchTextField() {
        searchTextField.edgeAnchors(top: mapView.topAnchor, padding: UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0))
        searchTextField.dimensionAnchors(height: 30, width: mapView.frame.width, widthMultiplier: 0.85)
        searchTextField.centerAnchors(centerX: mapView.centerXAnchor)
    }
    
    // Setup auto layout anchors for AR Session initialization button
    private func setupStartConnectSessionButton() {
        startConnectSessionButton.edgeAnchors(leading: mapView.leadingAnchor, bottom: mapView.bottomAnchor, padding: UIEdgeInsets(top: 0, left: 12, bottom: -12, right: 0))
        startConnectSessionButton.dimensionAnchors(height: 40, width: 100)
    }
    
    // Log out current user and return to login screen
    @objc private func logout() {
        do{
            try Auth.auth().signOut()
            AppDelegate.shared.rootViewController.switchToLogout()
        }catch let logoutError {
            print(logoutError)
        }
        
    }
    
    // Segue into AR Connect session
    @objc private func startARSession() {
        guard let location = locationModel.locationManager.location else{
            let alert = UIAlertController(title: "Error", message: "Current location is not available", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        let arSessionVC = ARSessionViewController()
        arSessionVC.currentLocation = location
        arSessionVC.targetLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: location.coordinate.latitude+0.00001, longitude: location.coordinate.longitude+0.00001), altitude: location.altitude, horizontalAccuracy: location.horizontalAccuracy, verticalAccuracy: location.verticalAccuracy, course: location.course, speed: location.speed, timestamp: location.timestamp)
        present(arSessionVC, animated: true, completion: nil)
    }
    
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
//    }
}
