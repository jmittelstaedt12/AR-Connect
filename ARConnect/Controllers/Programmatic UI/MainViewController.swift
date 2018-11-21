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
import SystemConfiguration

class MainViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var currentUser : User?
    var childSearchVCTopConstraint: NSLayoutConstraint?
    var searchViewControllerPreviousYCoordinate: CGFloat?
    
    let mapViewController = MapViewController()
    let childSearchViewController = SearchTableViewController()
    let userDetailViewController = CellDetailViewController()
    
    let viewARSessionButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("AR", for: .normal)
        btn.setTitleColor(UIColor.black, for: .normal)
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 5
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(startARSession), for: .touchUpInside)
        btn.isHidden = true
        return btn
    }()
    
    let endConnectSessionButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("End", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = btn.frame.size.height/2
        btn.backgroundColor = .red
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(endARSession), for: .touchUpInside)
        btn.isHidden = true
        return btn
    }()
    
    enum ExpansionState: CGFloat {
        case expanded
        case compressed
    }
    
    private func setChildSearchVCState(toState state: ExpansionState) {
        guard let tc = childSearchVCTopConstraint else {
            return
        }
        switch state {
        case .compressed:
            tc.constant = -50
            searchViewControllerPreviousYCoordinate = view.bounds.height - 50
        case .expanded:
            tc.constant = -400
            searchViewControllerPreviousYCoordinate = view.bounds.height - 400
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setupNavigationBarAttributes()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if Auth.auth().currentUser?.uid == nil {
            AppDelegate.shared.rootViewController.switchToLogout()
        }
        currentUser = Auth.auth().currentUser!
        FirebaseClient.usersRef.child(currentUser!.uid).child("isOnline").onDisconnectSetValue(false)
        setConnectionRequestObserver()
        setConnectionStartObserver()
        
        title = "AR Connect"
        let logoutButton = UIBarButtonItem(title: "Log Out", style: .plain, target: self, action: #selector(logout))
        navigationItem.setLeftBarButton(logoutButton, animated: true)
        
        addChildViews()
        setupMap()
        setupChildSearchViewController()
        setupUserDetailViewController()
        setupStartConnectSessionButton()
        
        childSearchViewController.delegate = self
        hideKeyboardWhenTappedAround()
    }
    
    private func addChildViews(){
        //view.addSubview(mapView)
        view.addSubview(mapViewController.view)
        mapViewController.didMove(toParent: self)
        view.addSubview(viewARSessionButton)
        addChild(childSearchViewController)
        view.addSubview(childSearchViewController.view)
        childSearchViewController.didMove(toParent: self)
        addChild(userDetailViewController)
        view.addSubview(userDetailViewController.view)
        userDetailViewController.didMove(toParent: self)
    }
    
    private func setupNavigationBarAttributes(){
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.barTintColor = UIColor.gray
        navigationController?.navigationBar.alpha = 0.9
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    }
    // Setup auto layout anchors for map view
    private func setupMap() {
        mapViewController.view.edgeAnchors(top: view.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor)
    }
    
    // Setup auto layout anchors for AR Session initialization button
    private func setupStartConnectSessionButton() {
        viewARSessionButton.edgeAnchors(leading: mapViewController.view.leadingAnchor, bottom: mapViewController.view.bottomAnchor, padding: UIEdgeInsets(top: 0, left: 12, bottom: -12, right: 0))
        viewARSessionButton.dimensionAnchors(height: 40, width: 100)
    }
    
    // Setup auto layout anchors for child instance SearchViewController
    private func setupChildSearchViewController() {
        childSearchViewController.view.edgeAnchors(leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4))
        childSearchVCTopConstraint = childSearchViewController.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        setChildSearchVCState(toState: .compressed)
        childSearchVCTopConstraint?.isActive = true
        childSearchViewController.view.dimensionAnchors(height: 667)
    }
    
    private func setupUserDetailViewController() {
        userDetailViewController.view.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: UIEdgeInsets(top: 40, left: 40, bottom: -40, right: -40))
    }
    
    private func setConnectionRequestObserver() {
        FirebaseClient.observeUidValue(forKey: "requestingUser") { (requestingUser) in
            let connectRequestVC = ConnectRequestViewController()
            connectRequestVC.requestingUser = requestingUser
            self.present(connectRequestVC, animated: true, completion: nil)
        }
    }
    
    private func setConnectionStartObserver() {
    #warning("add observer for if connection starts")
    }
    
    // Log out current user and return to login screen
    @objc private func logout() {
        currentUser = nil
        if FirebaseClient.logoutOfDB(controller: self){
            mapViewController.locationModel.locationManager.stopUpdatingLocation()
            AppDelegate.shared.rootViewController.switchToLogout()
        }
    }
    
    // Segue into AR Connect session
    @objc private func startARSession() {
        guard let location = mapViewController.locationModel.locationManager.location else{
            self.createAndDisplayAlert(withTitle: "Error", body: "Current location is not available")
            return
        }
        let arSessionVC = ARSessionViewController()
        arSessionVC.currentLocation = location
        arSessionVC.targetLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: location.coordinate.latitude+0.00001, longitude: location.coordinate.longitude+0.00001), altitude: location.altitude, horizontalAccuracy: location.horizontalAccuracy, verticalAccuracy: location.verticalAccuracy, course: location.course, speed: location.speed, timestamp: location.timestamp)
        present(arSessionVC, animated: true, completion: nil)
    }
    
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate, let user = currentUser else { return }
//        FirebaseClient.usersRef.child(user.uid).updateChildValues(["latitude" : locValue.latitude, "longitude" : locValue.longitude])
//    }
    
    @objc private func endARSession() {
        #warning("TODO: write end session logic")
    }
}

extension MainViewController: SearchTableViewControllerDelegate {
    
    // During pan of drawer VC, update child coordinates to match
    func updateCoordinatesDuringPan(to translationPoint: CGPoint, withVelocity velocity: CGPoint) {
        childSearchViewController.view.isUserInteractionEnabled = false
        guard let previousYCoordinate = searchViewControllerPreviousYCoordinate, let topConstraint = childSearchVCTopConstraint else{
            return
        }
        let constraintOffset = previousYCoordinate - view.bounds.height
        let newTopConstraint = previousYCoordinate + translationPoint.y
        let compressedYCoordinate = view.bounds.height - 50
        let expandedYCoordinate = view.bounds.height - 400
        if newTopConstraint >= expandedYCoordinate - 20 && newTopConstraint <= compressedYCoordinate + 20 {
            topConstraint.constant = constraintOffset+translationPoint.y
        }
    }
    
    // When release pan, update coordinates to compressed or expanded depending on velocity
    func updateCoordinatesAfterPan(to translationPoint: CGPoint, withVelocity velocity: CGPoint) {
        guard let previousYCoordinate = searchViewControllerPreviousYCoordinate else{
            return
        }
        let newTopConstraint = previousYCoordinate + translationPoint.y
        let compressedYCoordinate = view.frame.height-50
        let expandedYCoordinate = view.frame.height-400
        let velocityThreshold: CGFloat = 300
        if abs(velocity.y) < velocityThreshold {
            if previousYCoordinate == compressedYCoordinate {
                if newTopConstraint <= compressedYCoordinate-100 {
                    setChildSearchVCState(toState: .expanded)
                } else {
                    setChildSearchVCState(toState: .compressed)
                }
            } else {
                if newTopConstraint >= expandedYCoordinate+100{
                    setChildSearchVCState(toState: .compressed)
                } else {
                    setChildSearchVCState(toState: .expanded)
                }
            }
        
        } else {
            if previousYCoordinate == compressedYCoordinate {
                if newTopConstraint <= compressedYCoordinate {
                    setChildSearchVCState(toState: .expanded)
                } else {
                    setChildSearchVCState(toState: .compressed)
                }
            } else {
                if newTopConstraint >= expandedYCoordinate{
                    setChildSearchVCState(toState: .compressed)
                } else {
                    setChildSearchVCState(toState: .expanded)
                }
            }
        }
        animateTopConstraint()
    }
    
    // Animate transition to compressed or expanded and make view interactive again
    private func animateTopConstraint() {
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 4, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        })
        self.childSearchViewController.view.isUserInteractionEnabled = true

    }
    
    // Animate transition to expanded from compressed
    func animateToExpanded() {
        setChildSearchVCState(toState: .expanded)
        animateTopConstraint()
    }
    
    // Make card for tapped user visible in view
    func setChildUserDetailVCVisible(withUser user: LocalUser) {
        userDetailViewController.userForCell = user
        userDetailViewController.view.isHidden = false
    }
}

extension MainViewController: ConnectRequestDelegate {
    func startSession() {
        childSearchViewController.view.isHidden = true
        viewARSessionButton.isHidden = false
    }
}
