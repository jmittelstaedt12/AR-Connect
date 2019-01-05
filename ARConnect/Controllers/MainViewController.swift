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

class MainViewController: UIViewController {
    
    var currentUser : User?
    var childSearchVCTopConstraint: NSLayoutConstraint?
    var searchViewControllerPreviousYCoordinate: CGFloat?
    var arSessionViewController: ARSessionViewController?

    let connectNotificationName = Notification.Name(NotificationConstants.connectionNotificationKey)
    let mapViewController = MapViewController()
    let searchViewController = SearchTableViewController()
    let cardDetailViewController = CellDetailViewController()
    
    let viewARSessionButton: ARSessionButton = {
        let btn = ARSessionButton(type: .system)
        btn.setTitle("AR", for: .normal)
        btn.addTarget(self, action: #selector(startARSession), for: .touchUpInside)
        return btn
    }()
    
    let endConnectSessionButton: ARSessionButton = {
        let btn = ARSessionButton(type: .system)
        btn.setTitle("End", for: .normal)
        btn.addTarget(self, action: #selector(endARSession), for: .touchUpInside)
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
//        setupNavigationBarAttributes()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentUser = Auth.auth().currentUser!
        #warning("uncomment this line later")
//        FirebaseClient.usersRef.child(currentUser!.uid).child("connectedTo").onDisconnectSetValue("")
        setConnectionRequestObserver()
        
//        navigationController?.navigationBar = JMNavigationBar()
        title = "AR Connect"
        let logoutButton = UIBarButtonItem(title: "Log Out", style: .plain, target: self, action: #selector(logout))
        navigationItem.setLeftBarButton(logoutButton, animated: true)
        
        addSubviewsAndChildVCs()
        setupSubviewsAndChildVCs()
        searchViewController.delegate = self
        hideKeyboardWhenTappedAround()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleSessionStart(notification:)), name: connectNotificationName, object: nil)
    }
    
    /// Add all subviews and child view controllers to main view controller
    private func addSubviewsAndChildVCs() {
        addChild(mapViewController)
        view.addSubview(mapViewController.view)
        mapViewController.didMove(toParent: self)
        view.addSubview(viewARSessionButton)
        view.addSubview(endConnectSessionButton)
        addChild(searchViewController)
        view.addSubview(searchViewController.view)
        searchViewController.didMove(toParent: self)
        addChild(cardDetailViewController)
        view.addSubview(cardDetailViewController.view)
        cardDetailViewController.didMove(toParent: self)
    }
    
    /// Setup auto layout anchors, dimensions, and other position properties for subviews
    private func setupSubviewsAndChildVCs() {
        // Setup auto layout anchors for map view
        mapViewController.view.edgeAnchors(top: view.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor)
        
        // Setup auto layout anchors for viewARSession button
        viewARSessionButton.edgeAnchors(leading: mapViewController.view.leadingAnchor, bottom: searchViewController.view.topAnchor, padding: UIEdgeInsets(top: 0, left: 12, bottom: -12, right: 0))
        viewARSessionButton.dimensionAnchors(height: 40, width: 100)
        
        // Setup auto layout anchors for endConnectSession button
        endConnectSessionButton.edgeAnchors(bottom: searchViewController.view.topAnchor, trailing: mapViewController.view.trailingAnchor, padding: UIEdgeInsets(top: 0, left: 0, bottom: -12, right: -12))
        
        // Setup auto layout anchors for searchViewController
        searchViewController.view.edgeAnchors(leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4))
        childSearchVCTopConstraint = searchViewController.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        setChildSearchVCState(toState: .compressed)
        childSearchVCTopConstraint?.isActive = true
        searchViewController.view.dimensionAnchors(height: 667)
        
        // Setup auto layout anchors for cardDetailViewController
        cardDetailViewController.view.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: UIEdgeInsets(top: 40, left: 40, bottom: -40, right: -40))
    }
    
    private func setConnectionRequestObserver() {
        FirebaseClient.observeUidValue(forKey: "requestingUser") { (requestingUser) in
            let connectRequestVC = ConnectRequestViewController()
            connectRequestVC.requestingUser = requestingUser
            self.present(connectRequestVC, animated: true, completion: nil)
        }
    }
    
    /// Log out current user and return to login screen
    @objc private func logout() {
        currentUser = nil
        if FirebaseClient.logoutOfDB(controller: self) {
            AppDelegate.shared.rootViewController.switchToLogout()
        }
    }
    
    /// When connect to user, transition into AR Session state
    @objc private func handleSessionStart(notification: NSNotification) {
        searchViewController.view.isHidden = true
        viewARSessionButton.isHidden = false
        endConnectSessionButton.isHidden = false
        guard let location = mapViewController.locationService.locationManager.location else{
            self.createAndDisplayAlert(withTitle: "Error", body: "Current location is not available")
            return
        }
        arSessionViewController = ARSessionViewController()
        arSessionViewController!.startLocation = location
        arSessionViewController!.targetLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: location.coordinate.latitude+0.00001, longitude: location.coordinate.longitude+0.00001), altitude: location.altitude, horizontalAccuracy: location.horizontalAccuracy, verticalAccuracy: location.verticalAccuracy, course: location.course, speed: location.speed, timestamp: location.timestamp)
        arSessionViewController!.currentLocation = location
        arSessionViewController!.tripCoordinates = mapViewController.tripCoordinates
        mapViewController.delegate = arSessionViewController
    }
    
    /// Segue into AR Connect session
    @objc private func startARSession() {
        guard let arSessionVC = arSessionViewController else { return }
        present(arSessionVC, animated: true, completion: nil)
    }
    
    @objc private func endARSession() {
        #warning("TODO: write end session logic")
        arSessionViewController = nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        mapViewController.locationService.locationManager.stopUpdatingLocation()
    }
}



extension MainViewController: SearchTableViewControllerDelegate {
    
    /// During pan of drawer VC, update child coordinates to match
    func updateCoordinatesDuringPan(to translationPoint: CGPoint, withVelocity velocity: CGPoint) {
        searchViewController.view.isUserInteractionEnabled = false
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
    
    /// When release pan, update coordinates to compressed or expanded depending on velocity
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
    
    /// Animate transition to compressed or expanded and make view interactive again
    private func animateTopConstraint() {
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 4, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        })
        self.searchViewController.view.isUserInteractionEnabled = true

    }
    
    /// Animate transition to expanded from compressed
    func animateToExpanded() {
        setChildSearchVCState(toState: .expanded)
        animateTopConstraint()
    }
    
    /// Make card for tapped user visible in view
    func setChildUserDetailVCVisible(withUser user: LocalUser) {
        cardDetailViewController.userForCell = user
        cardDetailViewController.view.isHidden = false
    }
}
