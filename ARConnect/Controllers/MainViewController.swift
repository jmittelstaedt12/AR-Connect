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
import RxSwift

final class MainViewController: UIViewController {
    
    var currentUser : User?
    var childSearchVCTopConstraint: NSLayoutConstraint?
    var searchViewControllerPreviousYCoordinate: CGFloat?
    var arSessionViewController: ARSessionViewController?
    let bag = DisposeBag()

    let connectNotificationName = Notification.Name(NotificationConstants.connectionNotificationKey)
    let mapViewController = MapViewController()
    var searchViewController: SearchTableViewController? = SearchTableViewController()
    
    var viewARSessionButton: ARSessionButton? {
        willSet {
            newValue?.setTitle("AR", for: .normal)
            newValue?.addTarget(self, action: #selector(startARSession), for: .touchUpInside)
        }
    }
    
    var endConnectSessionButton: ARSessionButton? {
        willSet {
            newValue?.setTitle("End", for: .normal)
            newValue?.addTarget(self, action: #selector(endARSession), for: .touchUpInside)
        }
    }
    
    private func setChildSearchVCState(toState state: SearchTableViewController.ExpansionState) {
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
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentUser = Auth.auth().currentUser!
        if Auth.auth().currentUser == nil { AppDelegate.shared.rootViewController.switchToLogout() }
        else { currentUser = Auth.auth().currentUser! }
        FirebaseClient.setOnDisconnectUpdates(withUid: currentUser!.uid)
        setObservers()
//        navigationController?.navigationBar = JMNavigationBar()
        let logoutButton = UIBarButtonItem(title: "Log Out", style: .plain, target: self, action: #selector(logout))
        navigationItem.setLeftBarButton(logoutButton, animated: true)
        
        addSubviewsAndChildVCs()
        setupSubviewsAndChildVCs()
        searchViewController?.delegate = self
        hideKeyboardWhenTappedAround()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleSessionStart(notification:)), name: connectNotificationName, object: nil)
    }
    
    /// Add all subviews and child view controllers to main view controller
    private func addSubviewsAndChildVCs() {
        addChild(mapViewController)
        view.addSubview(mapViewController.view)
        mapViewController.didMove(toParent: self)
        guard let searchVC = searchViewController else { return }
        addChild(searchVC)
        view.addSubview(searchVC.view)
        searchVC.didMove(toParent: self)
    }
    
    /// Setup auto layout anchors, dimensions, and other position properties for subviews
    private func setupSubviewsAndChildVCs() {
        // Setup auto layout anchors for map view
        mapViewController.view.edgeAnchors(top: view.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor)
        
        // Setup auto layout anchors for searchViewController
        guard let searchVC = searchViewController else { return }
        searchVC.view.edgeAnchors(leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4))
        childSearchVCTopConstraint = searchVC.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        setChildSearchVCState(toState: .compressed)
        childSearchVCTopConstraint?.isActive = true
        searchVC.view.dimensionAnchors(height: 400)
    }
    
    private func setObservers() {
        
        // Set one time connection for nav bar title
        FirebaseClient.fetchObservableUser(withUid: currentUser!.uid).subscribe(onNext: { (user) in
            self.title = user.name
        }).disposed(by: self.bag)
        
        // Setting online status observer
        FirebaseClient.createAmOnlineObservable().subscribe(onNext: { (connected) in
            guard let uid = self.currentUser?.uid else { return }
            FirebaseClient.usersRef.child(uid).updateChildValues(["isOnline": connected])
        }).disposed(by: self.bag)
        
        // Setting connection request observer
        FirebaseClient.willDisplayRequestingUserObservable().subscribe(onNext: { (requestingUser) in
            let connectRequestVC = ConnectRequestViewController()
            connectRequestVC.user = requestingUser
            self.present(connectRequestVC, animated: true, completion: nil)
        }).disposed(by: self.bag)
    }
    
    /// Log out current user and return to login screen
    @objc private func logout() {
        do {
            try FirebaseClient.logoutOfDB()
            AppDelegate.shared.rootViewController.switchToLogout()
        } catch let logoutError {
            createAndDisplayAlert(withTitle: "Log out Error", body: logoutError.localizedDescription)
        }
    }
        
    
    /// When connect to user, transition into AR Session state
    @objc private func handleSessionStart(notification: NSNotification) {
        searchViewController = nil
        viewARSessionButton = ARSessionButton(type: .system)
        endConnectSessionButton = ARSessionButton(type: .system)
        
        view.addSubview(viewARSessionButton!)
        view.addSubview(endConnectSessionButton!)
        
        // Setup auto layout anchors for viewARSession button
        viewARSessionButton!.edgeAnchors(leading: mapViewController.view.leadingAnchor, bottom: mapViewController.view.bottomAnchor, padding: UIEdgeInsets(top: 0, left: 12, bottom: -12, right: 0))
        viewARSessionButton!.dimensionAnchors(height: 40, width: 100)
        
        // Setup auto layout anchors for endConnectSession button
        endConnectSessionButton!.edgeAnchors(bottom: mapViewController.view.bottomAnchor, trailing: mapViewController.view.trailingAnchor, padding: UIEdgeInsets(top: 0, left: 0, bottom: -12, right: -12))
        
        view.updateConstraintsIfNeeded()
        
        guard let location = mapViewController.locationService.locationManager.location else {
            createAndDisplayAlert(withTitle: "Error", body: "Current location is not available")
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
        viewARSessionButton = nil
        endConnectSessionButton = nil
        searchViewController = SearchTableViewController()
        searchViewController!.delegate = self
        addChild(searchViewController!)
        view.addSubview(searchViewController!.view)
        searchViewController!.didMove(toParent: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        mapViewController.locationService.locationManager.stopUpdatingLocation()
    }
}



extension MainViewController: SearchTableViewControllerDelegate {
    
    /// During pan of drawer VC, update child coordinates to match
    func updateCoordinatesDuringPan(to translationPoint: CGPoint, withVelocity velocity: CGPoint) {
        guard let searchVC = searchViewController else { return }
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
        searchVC.view.isUserInteractionEnabled = false
    }
    
    /// When release pan, update coordinates to compressed or expanded depending on velocity
    func updateCoordinatesAfterPan(to translationPoint: CGPoint, withVelocity velocity: CGPoint) {
        guard let searchVC = searchViewController, let previousYCoordinate = searchViewControllerPreviousYCoordinate else { return }
        let newTopConstraint = previousYCoordinate + translationPoint.y
        let compressedYCoordinate = view.frame.height-50
        let expandedYCoordinate = view.frame.height-400
        let velocityThreshold: CGFloat = 300
        if abs(velocity.y) < velocityThreshold {
            if previousYCoordinate == compressedYCoordinate {
                if newTopConstraint <= compressedYCoordinate-100 {
                    searchVC.expansionState = .expanded
                } else {
                    searchVC.expansionState = .compressed
                }
            } else {
                if newTopConstraint >= expandedYCoordinate+100 {
                    searchVC.expansionState = .compressed
                } else {
                    searchVC.expansionState = .expanded
                }
            }
        
        } else {
            if previousYCoordinate == compressedYCoordinate {
                if newTopConstraint <= compressedYCoordinate {
                    searchVC.expansionState = .expanded
                } else {
                    searchVC.expansionState = .compressed
                }
            } else {
                if newTopConstraint >= expandedYCoordinate{
                    searchVC.expansionState = .compressed
                } else {
                    searchVC.expansionState = .expanded
                }
            }
        }
        setChildSearchVCState(toState: searchVC.expansionState)
        animateTopConstraint()
    }
    
    /// Animate transition to compressed or expanded and make view interactive again
    private func animateTopConstraint() {
        guard let searchVC = searchViewController else { return }
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 4, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        })
        searchVC.view.isUserInteractionEnabled = true
    }
    
//    /// Animate transition to expanded from compressed
    func animateToExpanded() {
        setChildSearchVCState(toState: .expanded)
        animateTopConstraint()
    }
    
    /// Make card for tapped user visible in view
    func setChildUserDetailVCVisible(withUser user: LocalUser) {
        let cardDetailVC = CardDetailViewController()
        addChild(cardDetailVC)
        view.addSubview(cardDetailVC.view)
        cardDetailVC.didMove(toParent: self)
        cardDetailVC.userForCell = user
        cardDetailVC.delegate = self
        cardDetailVC.view.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: UIEdgeInsets(top: 40, left: 40, bottom: -40, right: -40))
        view.updateConstraintsIfNeeded()
    }
}

extension MainViewController: CardDetailDelegate {
    func subscribeToCallUserObservable(forUser user: LocalUser) {
        FirebaseClient.createCallUserObservable(withUid: user.uid!).subscribe(onNext: { (canComplete) in
            if canComplete {
                FirebaseClient.usersRef.child(Auth.auth().currentUser!.uid).updateChildValues(["pendingRequest" : true])
                FirebaseClient.usersRef.child(user.uid!).updateChildValues(["requestingUser" : Auth.auth().currentUser!.uid])
                let connectPendingVC = ConnectPendingViewController()
                connectPendingVC.user = user
                self.present(connectPendingVC, animated: true, completion: nil)
            } else {
                self.createAndDisplayAlert(withTitle: "Connection Error", body: "User\(user.name != nil ? (" " + user.name!) : "") is unavailable")
            }
        }, onError: { (error) in
            self.createAndDisplayAlert(withTitle: "Connection Error", body: error.localizedDescription)
        }).disposed(by: bag)
    }
}
