//
//  MainViewController.swift
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
import RxCocoa

final class MainViewController: UIViewController {

    // MARK: Properties
    var currentUser: User?
    var childSearchVCTopConstraint: NSLayoutConstraint?
    var childSearchVCHeightConstraint: NSLayoutConstraint?
    var searchViewControllerPreviousYCoordinate: CGFloat?
    let bag = DisposeBag()

    private let connectNotificationName = Notification.Name(NotificationConstants.requestResponseNotificationKey)
    let mapViewController = MapViewController()
    var searchViewController: SearchTableViewController? = SearchTableViewController()
    weak var arSessionVC: ARSessionViewController?

    var buttonCollection: CollapsibleCollectionView?

    var viewARSessionButton: ARSessionButton? {
        willSet {
            newValue?.setTitle("AR", for: .normal)
            newValue?.addTarget(self, action: #selector(startARSession), for: .touchUpInside)
            newValue?.layer.cornerRadius = 30
            newValue?.dimensionAnchors(height: 60, width: 60)
        }
    }

    var endConnectSessionButton: ARSessionButton? {
        willSet {
            newValue?.setTitle("End", for: .normal)
            newValue?.addTarget(self, action: #selector(didDisconnect), for: .touchUpInside)
            newValue?.layer.cornerRadius = 30
            newValue?.dimensionAnchors(height: 60, width: 60)
        }
    }

    var expandedHeight: CGFloat = 400 {
        willSet {
            childSearchVCHeightConstraint?.constant = newValue
            childSearchVCTopConstraint?.constant = -newValue
        }
    }

    let compressedHeight: CGFloat = 50

    // MARK: Methods
    private func setChildSearchVCState(toState state: SearchTableViewController.ExpansionState) {
        guard let topConstraint = childSearchVCTopConstraint else {
            return
        }
        switch state {
        case .compressed:
            topConstraint.constant = -50
            searchViewControllerPreviousYCoordinate = view.bounds.height - compressedHeight
        case .expanded:
            topConstraint.constant = -400
            searchViewControllerPreviousYCoordinate = view.bounds.height - expandedHeight
        }
    }

    var cardDetailViewController: CardDetailViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        if Auth.auth().currentUser == nil {
            AppDelegate.shared.rootViewController.switchToLogout()
        }
        currentUser = Auth.auth().currentUser!
        FirebaseClient.setOnDisconnectUpdates(forUid: currentUser!.uid)
        setObservers()
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
        mapViewController.view.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor)

        // Setup auto layout anchors for searchViewController
        guard let searchVC = searchViewController else { return }
        searchVC.view.edgeAnchors(leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4))
        childSearchVCTopConstraint = searchVC.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        childSearchVCHeightConstraint = searchVC.view.heightAnchor.constraint(equalToConstant: expandedHeight)
        childSearchVCTopConstraint?.isActive = true
        childSearchVCHeightConstraint?.isActive = true
        searchVC.expansionState = .compressed
        setChildSearchVCState(toState: searchVC.expansionState)
    }

    private func setObservers() {

        // Set one time connection for nav bar title
        FirebaseClient.fetchObservableUser(forUid: currentUser!.uid).subscribe(onNext: { [weak self] user in
            self?.title = user.name
        }).disposed(by: self.bag)

        // Setting online status observer
        FirebaseClient.createAmOnlineObservable().subscribe(onNext: { [weak self] connected in
            guard let uid = self?.currentUser?.uid else { return }
            FirebaseClient.usersRef.child(uid).updateChildValues(["isOnline": connected])
        }).disposed(by: self.bag)

        // Setting connection request observer
        FirebaseClient.willDisplayRequestingUserObservable()?.subscribe(onNext: { [weak self] (requestingUser, requestDictionary) in
            let connectRequestVC = ConnectRequestViewController(requestingUser: requestingUser,
                                                                meetupLocation: CLLocation(latitude: requestDictionary["latitude"] as! Double, longitude: requestDictionary["longitude"] as! Double),
                                                                currentLocation: self?.mapViewController.currentLocation)
            self?.present(connectRequestVC, animated: true, completion: nil)
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

    private func requestToConnectWithUser(_ user: LocalUser, atCoordinate coordinate: CLLocationCoordinate2D) {
        FirebaseClient.usersRef.child(Auth.auth().currentUser!.uid).updateChildValues(["pendingRequest": true]) { [weak self] (error, _) in
            guard let self = self else { return }
            if let err = error {
                self.createAndDisplayAlert(withTitle: "Error", body: err.localizedDescription)
                return
            }
            FirebaseClient.createCallUserObservable(forUid: user.uid!, atCoordinateTuple: (latitude: coordinate.latitude, longitude: coordinate.longitude)).subscribe(onNext: { [weak self] completed in
                guard completed else { return }
                let connectPendingVC = ConnectPendingViewController(requestingUser: user, meetupLocation: CLLocation(coordinate: coordinate))
                self?.present(connectPendingVC, animated: true, completion: nil)
            }, onError: { [weak self] error in
                self?.createAndDisplayAlert(withTitle: "Connection Error", body: error.localizedDescription)
            }).disposed(by: self.bag)
        }
    }

    /// When connect to user, transition into AR Session state
    @objc private func handleSessionStart(notification: NSNotification) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let user = notification.userInfo?["user"] as! LocalUser
        let didConnect = notification.userInfo?["didConnect"] as! Bool

        if !didConnect {
            createAndDisplayAlert(withTitle: "Call Ending", body: "\(user.name ?? "User") is unavailable")
            if let searchVC = searchViewController {
                searchVC.expansionState = .compressed
                setChildSearchVCState(toState: searchVC.expansionState)
                animateTopConstraint()
            }
            return
        }

        FirebaseClient.usersRef.child(currentUid).updateChildValues(["isPending": false, "isConnected": true, "connectedTo": user.uid])

        searchViewController?.willMove(toParent: nil)
        searchViewController?.view.removeFromSuperview()
        searchViewController?.removeFromParent()
        searchViewController = nil

        viewARSessionButton = ARSessionButton(type: .system)
        endConnectSessionButton = ARSessionButton(type: .system)

        view.addSubview(viewARSessionButton!)
        view.addSubview(endConnectSessionButton!)

        // Setup auto layout anchors for endConnectSession button
        viewARSessionButton!.edgeAnchors(bottom: mapViewController.view.bottomAnchor, trailing: mapViewController.view.trailingAnchor, padding: UIEdgeInsets(top: 0, left: 0, bottom: -12, right: -12))

        // Setup auto layout anchors for endConnectSession button
        endConnectSessionButton!.edgeAnchors(bottom: viewARSessionButton?.topAnchor, trailing: mapViewController.view.trailingAnchor, padding: UIEdgeInsets(top: 0, left: 0, bottom: -12, right: -12))

        initializeButtonCollection()
        buttonCollection!.edgeAnchors(leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, padding: UIEdgeInsets(top: 0, left: 12, bottom: -12, right: 0))
        buttonCollection!.dimensionAnchors(height: 500, width: 50)
        view.layoutIfNeeded()

//        guard let currentUid = Auth.auth().currentUser?.uid else { return }
//
//        let user = notification.userInfo?["user"] as! LocalUser
//        let didConnect = notification.userInfo?["didConnect"] as! Bool
//
//        if !didConnect {
//            createAndDisplayAlert(withTitle: "Call Ending", body: "\(user.name ?? "User") is unavailable")
//            if let searchVC = searchViewController {
//                searchVC.expansionState = .compressed
//                setChildSearchVCState(toState: searchVC.expansionState)
//                animateTopConstraint()
//            }
//            return
//        }
//
//        FirebaseClient.usersRef.child(currentUid).updateChildValues(["isPending": false, "isConnected": true, "connectedTo": user.uid])
//
//        searchViewController?.willMove(toParent: nil)
//        searchViewController?.view.removeFromSuperview()
//        searchViewController?.removeFromParent()
//        searchViewController = nil
//
//        viewARSessionButton = ARSessionButton(type: .system)
//        endConnectSessionButton = ARSessionButton(type: .system)
//
//        view.addSubview(viewARSessionButton!)
//        view.addSubview(endConnectSessionButton!)
//
//        // Setup auto layout anchors for viewARSession button
//        viewARSessionButton!.edgeAnchors(leading: mapViewController.view.leadingAnchor, bottom: mapViewController.view.bottomAnchor, padding: UIEdgeInsets(top: 0, left: 12, bottom: -12, right: 0))
//        viewARSessionButton!.dimensionAnchors(height: 40, width: 100)
//
//        // Setup auto layout anchors for endConnectSession button
//        endConnectSessionButton!.edgeAnchors(bottom: mapViewController.view.bottomAnchor, trailing: mapViewController.view.trailingAnchor, padding: UIEdgeInsets(top: 0, left: 0, bottom: -12, right: -12))
//
//        view.layoutIfNeeded()
//
        FirebaseClient.createEndSessionObservable(forUid: user.uid)?.subscribe(onNext: { [unowned self] _ in
            self.handleSessionEnd()
        }).disposed(by: bag)
    }

    private func initializeButtonCollection() {
        let centerLocationButton = UIButton()
        centerLocationButton.setTitle("Center", for: .normal)
        centerLocationButton.setTitleColor(.black, for: .normal)
        centerLocationButton.addTarget(mapViewController, action: #selector(mapViewController.centerAtLocation), for: .touchUpInside)
        let centerPathButton = UIButton()
        centerPathButton.setTitle("Path", for: .normal)
        centerPathButton.setTitleColor(.black, for: .normal)
        centerPathButton.addTarget(mapViewController, action: #selector(mapViewController.centerAtPath), for: .touchUpInside)
        buttonCollection = CollapsibleCollectionView(frame: view.frame, collectionViewLayout: UICollectionViewFlowLayout(),
                                                     collapsed: true, buttons: [centerLocationButton, centerPathButton], growDirection: .fromBottom)
        view.addSubview(buttonCollection!)
    }

    @objc private func handleSessionEnd() {
        guard let user = currentUser else { return }
        FirebaseClient.usersRef.child(user.uid).updateChildValues(["connectedTo": "",
                                                                   "isConnected": false])
        viewARSessionButton?.removeFromSuperview()
        endConnectSessionButton?.removeFromSuperview()
        buttonCollection?.removeFromSuperview()
        viewARSessionButton = nil
        endConnectSessionButton = nil
        buttonCollection = nil
        searchViewController = SearchTableViewController()
        searchViewController!.delegate = self
        addChild(searchViewController!)
        view.addSubview(searchViewController!.view)
        searchViewController!.didMove(toParent: self)
        setupSubviewsAndChildVCs()
        mapViewController.resetMap()
    }

    /// Segue into AR Connect session
    @objc private func startARSession() {
        guard let location = mapViewController.currentLocation else {
            createAndDisplayAlert(withTitle: "Error", body: "Current location is not available")
            return
        }
        let arSessionVC = ARSessionViewController()
        arSessionVC.startLocation = location
        arSessionVC.currentLocation = location
        arSessionVC.tripCoordinates = mapViewController.tripCoordinates

        switch mapViewController.shouldUseAlignment {
        case .gravity:
            createAndDisplayAlert(withTitle: "Poor Heading Accuracy", body: "Tap left and right side of the screen to adjust direction of True North")
            arSessionVC.worldAlignment = .gravity
        case .gravityAndHeading:
            arSessionVC.worldAlignment = .gravityAndHeading
        }

        self.arSessionVC = arSessionVC
        mapViewController.delegate = self.arSessionVC
        mapViewController.locationService.locationManager.stopUpdatingHeading()
        present(arSessionVC, animated: true, completion: nil)
    }

    @objc private func didDisconnect() {
        guard let user = currentUser else { return }
        FirebaseClient.usersRef.child(user.uid).updateChildValues(["connectedTo": "",
                                                                   "isConnected": false])
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
        guard let previousYCoordinate = searchViewControllerPreviousYCoordinate, let topConstraint = childSearchVCTopConstraint else {
            return
        }
        let constraintOffset = previousYCoordinate - view.bounds.height
        let newTopConstraint = previousYCoordinate + translationPoint.y
        let compressedYCoordinate = view.bounds.height - 50
        let expandedYCoordinate = view.bounds.height - 400
        if newTopConstraint >= expandedYCoordinate && newTopConstraint <= compressedYCoordinate + 40 {
            topConstraint.constant = constraintOffset + translationPoint.y
        } else if newTopConstraint <= expandedYCoordinate && newTopConstraint >= expandedYCoordinate - 40 {
            expandedHeight = 400 + abs(newTopConstraint - expandedYCoordinate)
        }
        searchVC.tableView.alpha = (1.0/(-400)) * topConstraint.constant
        searchVC.view.isUserInteractionEnabled = false
    }

    /// When release pan, update coordinates to compressed or expanded depending on velocity
    func updateCoordinatesAfterPan(to translationPoint: CGPoint, withVelocity velocity: CGPoint) {
        guard let searchVC = searchViewController, let previousYCoordinate = searchViewControllerPreviousYCoordinate else { return }
        expandedHeight = 400
        let newTopConstraint = previousYCoordinate + translationPoint.y
        let compressedYCoordinate = view.frame.height - 50
        let expandedYCoordinate = view.frame.height - 400
        let velocityThreshold: CGFloat = 100
        if abs(velocity.y) < velocityThreshold {
            if previousYCoordinate == compressedYCoordinate {
                if newTopConstraint <= compressedYCoordinate-125 {
                    searchVC.expansionState = .expanded
                } else {
                    searchVC.expansionState = .compressed
                }
            } else {
                if newTopConstraint >= expandedYCoordinate + 125 {
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
                if newTopConstraint >= expandedYCoordinate {
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
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 4, options: .curveEaseOut, animations: {
            searchVC.tableView.alpha = (searchVC.expansionState == .compressed) ? 0.0 : 1.0
            self.view.layoutIfNeeded()
        })
        searchVC.view.isUserInteractionEnabled = true
    }

    /// Animate transition to expanded from compressed
    func animateToExpanded() {
        guard let searchVC = searchViewController else { return }
        searchVC.expansionState = .expanded
        setChildSearchVCState(toState: searchVC.expansionState)
        animateTopConstraint()
    }

    /// Make card for tapped user visible in view
    func setUserDetailCardVisible(withUser user: LocalUser) {
        cardDetailViewController = CardDetailViewController()
        addChild(cardDetailViewController!)
        view.addSubview(cardDetailViewController!.view)
        cardDetailViewController!.didMove(toParent: self)
        cardDetailViewController!.userForCell = user
        cardDetailViewController!.delegate = self
        let scale = min(view.bounds.height/896.0, view.bounds.width/414.0)
        cardDetailViewController!.view.transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
        cardDetailViewController!.view.dimensionAnchors(height: cardDetailViewController!.view.bounds.height, width: cardDetailViewController!.view.bounds.width)
        cardDetailViewController!.view.centerAnchors(centerX: view.centerXAnchor, centerY: view.centerYAnchor)

        view.updateConstraintsIfNeeded()
    }

    func updateDetailCard(withUser user: LocalUser) {
        guard let cardDetailVC = cardDetailViewController, let cellUser = cardDetailVC.userForCell, cellUser != user else { return }
        cardDetailVC.userForCell = user
    }
}

extension MainViewController: CardDetailDelegate {

    func removeFromHierarchy() {
        cardDetailViewController?.willMove(toParent: nil)
        cardDetailViewController?.view.removeFromSuperview()
        cardDetailViewController?.removeFromParent()
        cardDetailViewController = nil
    }

    func willSetMeetupLocation(withUser user: LocalUser) {
        searchViewController?.willMove(toParent: nil)
        searchViewController?.view.removeFromSuperview()
        searchViewController?.removeFromParent()
        searchViewController = nil
        navigationController?.navigationBar.isHidden = true

        mapViewController.willSetLocationMarker()

        mapViewController.meetupLocationObservable?.subscribe(onNext: { [weak self] coordinate in
            guard let self = self else { return }
            self.navigationController?.navigationBar.isHidden = false
            self.handleSessionEnd()
            self.requestToConnectWithUser(user, atCoordinate: coordinate)
        }).disposed(by: bag)

//
//        mapViewController.meetupLocationObservable?.subscribe(onNext: { [unowned self] coordinate in
//            self.navigationController?.navigationBar.isHidden = false
//            self.handleSessionEnd()
//            FirebaseClient.usersRef.child(self.currentUser!.uid).updateChildValues(["connectedTo": "afasf",
//                                                                       "isConnected": true])
//            let name = Notification.Name(rawValue: NotificationConstants.requestResponseNotificationKey)
//            NotificationCenter.default.post(name: name, object: nil, userInfo: ["user": user,
//                                                                                "meetupLocation": coordinate,
//                                                                                "didConnect": true])
//        }).disposed(by: bag)
    }

}


//        FirebaseClient.createCanCallUserObservable(forUid: user.uid!).subscribe(onNext: { [weak self] canComplete in
//            if canComplete {
//                self?.willSetMeetupLocation()
//            } else {
//                self?.createAndDisplayAlert(withTitle: "Connection Error", body: "User\(user.name != nil ? (" " + user.name!) : "") is unavailable")
//            }
//            }, onError: { [weak self] error in
//                self?.createAndDisplayAlert(withTitle: "Connection Error", body: error.localizedDescription)
//        }).disposed(by: bag)
//
//        FirebaseClient.createCanCallUserObservable(forUid: user.uid!).subscribe(onNext: { [weak self] canComplete in
//            if canComplete {
//                FirebaseClient.usersRef.child(Auth.auth().currentUser!.uid).updateChildValues(["pendingRequest": true])
//                FirebaseClient.usersRef.child(user.uid!).child("requestingUser").updateChildValues(["uid": Auth.auth().currentUser!.uid])
//                let connectPendingVC = ConnectPendingViewController()
//                connectPendingVC.user = user
//                self?.present(connectPendingVC, animated: true, completion: nil)
//            } else {
//                self?.createAndDisplayAlert(withTitle: "Connection Error", body: "User\(user.name != nil ? (" " + user.name!) : "") is unavailable")
//            }
//            }, onError: { (error) in
//                self.createAndDisplayAlert(withTitle: "Connection Error", body: error.localizedDescription)
//        }).disposed(by: bag)
