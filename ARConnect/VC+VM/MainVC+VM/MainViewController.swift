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

final class MainViewController: UIViewController, ControllerProtocol {

    // MARK: Properties

    typealias ViewModelType = MainViewModel

    var viewModel: ViewModelType!

    var childSearchVCTopConstraint: NSLayoutConstraint?
    var childSearchVCHeightConstraint: NSLayoutConstraint?
    var searchViewControllerPreviousYCoordinate: CGFloat?
    let bag = DisposeBag()

    private let connectNotificationName = Notification.Name(NotificationConstants.requestResponseNotificationKey)
    let mapViewController: MapViewController
    var searchViewController: SearchTableViewController? = SearchTableViewController(viewModel: SearchTableViewModel())
    var arSessionVC: ARSessionViewController?

    var buttonCollection: CollapsibleCollectionView?

    let profileBarButton: UIButton = {
        let rightButton = UIButton(type: .system)
        rightButton.backgroundColor = .lightGray
        rightButton.setBackgroundImage(UIImage(named: "person-placeholder"), for: .normal)
        rightButton.layoutIfNeeded()
        rightButton.subviews.first?.contentMode = .scaleAspectFill
        rightButton.addTarget(self, action: #selector(didTapProfileImage), for: .touchUpInside)
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.dimensionAnchors(height: 34, width: 34)
        rightButton.layer.cornerRadius = 17
        rightButton.layer.masksToBounds = true
        return rightButton
    }()

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
//            newValue?.addTarget(self, action: #selector(didDisconnect), for: .touchUpInside)
            newValue?.layer.cornerRadius = 30
            newValue?.dimensionAnchors(height: 60, width: 60)
            newValue?.rx.tap.asObservable()
                .subscribe(viewModel.input.disconnectDidTap)
                .disposed(by: disposeBag)
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
    let disposeBag = DisposeBag()

    func configure(with viewModel: ViewModelType) {

        viewModel.output.profileImageDataObservable
            .subscribe(onNext: { [weak self] data in
                DispatchQueue.main.async {
                    self?.profileBarButton.setBackgroundImage(UIImage(data: data), for: .normal)
                }
            })
            .disposed(by: disposeBag)

        viewModel.output.authenticatedUserObservable
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .success:
                    return
                case .failure(let error):
                    self?.createAndDisplayAlert(withTitle: error.title, body: error.errorDescription)
                    AppDelegate.shared.rootViewController.switchToLogout()
                }
            })
            .disposed(by: disposeBag)

        viewModel.output.connectRequestObservable
            .subscribe(onNext: { [weak self] connectRequestViewModel in
                DispatchQueue.main.async {
                    self?.present(ConnectRequestViewController(viewModel: connectRequestViewModel), animated: true)
                }
            })
            .disposed(by: disposeBag)

        viewModel.output.endSessionObservable
            .subscribe(onNext: { [weak self] in
                self?.handleSessionEnd()
            })
            .disposed(by: disposeBag)

        viewModel.output.sessionStartObservable
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .success:
                    self?.handleSessionStart()
                case .failure(let error):
                    self?.createAndDisplayAlert(withTitle: error.title, body: error.errorDescription)
                    if let searchVC = self?.searchViewController {
                        searchVC.expansionState = .compressed
                        self?.setChildSearchVCState(toState: searchVC.expansionState)
                        self?.animateTopConstraint()
                    }
                }
            })
            .disposed(by: disposeBag)

        viewModel.output.didSendConnectRequestObservable
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .success(let connectPendingViewModel):
                    DispatchQueue.main.async {
                        self?.present(ConnectPendingViewController(viewModel: connectPendingViewModel), animated: true)
                    }
                case .failure(let error):
                    self?.createAndDisplayAlert(withTitle: error.title, body: error.errorDescription)
                }
            })
            .disposed(by: disposeBag)

        mapViewController.viewModel.output.updatedCurrentLocationObservable
            .subscribe(onNext: { [weak self] location in
                self?.viewModel.currentLocation = location
            })
            .disposed(by: disposeBag)

    }

    let firebaseClient: FirebaseClient
    init(viewModel: ViewModelType, firebaseClient: FirebaseClient = FirebaseClient()) {
        self.viewModel = viewModel
        let mapVM = MapViewModel(uid: viewModel.uid)
        mapViewController = MapViewController(viewModel: mapVM)
        self.firebaseClient = firebaseClient
        super.init(nibName: nil, bundle: nil)
        configure(with: viewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBarItems()
        addSubviewsAndChildVCs()
        setupSubviewsAndChildVCs()
        searchViewController?.delegate = self
        hideKeyboardWhenTappedAround()
    }

    private func setupNavigationBarItems() {
        let titleView = UILabel()
        titleView.text = "AR Connect"
        titleView.textColor = .white
        navigationItem.titleView = titleView

        let leftButton = UIBarButtonItem(title: "Log Out", style: .plain, target: self, action: #selector(logout))
        navigationItem.leftBarButtonItem = leftButton

        navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: profileBarButton)]
    }

//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        let connectedUser = LocalUser(name: "Kevin", email: "Kevin@gmail.com", uid: "n13XNUAEb1bIcZF57fqVE9BHEzo2", isOnline: true)
//        let meetupLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.686991, longitude: -73.931020))
//        NotificationCenter.default.post(name: self.connectNotificationName, object: nil, userInfo: ["user": connectedUser,
//                                                                            "meetupLocation": meetupLocation,
//                                                                            "didConnect": true])
//    }

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
        mapViewController.view.edgeAnchors(top: view.topAnchor,
                                           leading: view.leadingAnchor,
                                           bottom: view.bottomAnchor,
                                           trailing: view.trailingAnchor)

        // Setup auto layout anchors for searchViewController
        guard let searchVC = searchViewController else { return }
        searchVC.view.edgeAnchors(leading: view.safeAreaLayoutGuide.leadingAnchor,
                                  trailing: view.safeAreaLayoutGuide.trailingAnchor,
                                  padding: UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4))
        childSearchVCTopConstraint = searchVC.view.topAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        childSearchVCHeightConstraint = searchVC.view.heightAnchor.constraint(equalToConstant: expandedHeight)
        childSearchVCTopConstraint?.isActive = true
        childSearchVCHeightConstraint?.isActive = true
        searchVC.expansionState = .compressed
        setChildSearchVCState(toState: searchVC.expansionState)
    }

    /// Log out current user and return to login screen
    @objc private func logout() {
        do {
            try firebaseClient.logoutOfDB()
            AppDelegate.shared.rootViewController.switchToLogout()
        } catch let logoutError {
            createAndDisplayAlert(withTitle: "Log out Error", body: logoutError.localizedDescription)
        }
    }

    @objc private func didTapProfileImage() {

    }

    /// When connect to user, transition into AR Session state
    private func handleSessionStart() {

        searchViewController?.willMove(toParent: nil)
        searchViewController?.view.removeFromSuperview()
        searchViewController?.removeFromParent()
        searchViewController = nil

        viewARSessionButton = ARSessionButton(type: .system)
        endConnectSessionButton = ARSessionButton(type: .system)

        view.addSubview(viewARSessionButton!)
        view.addSubview(endConnectSessionButton!)

        // Setup auto layout anchors for endConnectSession button
        viewARSessionButton!.edgeAnchors(bottom: mapViewController.view.bottomAnchor,
                                         trailing: mapViewController.view.trailingAnchor,
                                         padding: UIEdgeInsets(top: 0, left: 0, bottom: -12, right: -12))

        // Setup auto layout anchors for endConnectSession button
        endConnectSessionButton!.edgeAnchors(bottom: viewARSessionButton?.topAnchor,
                                             trailing: mapViewController.view.trailingAnchor,
                                             padding: UIEdgeInsets(top: 0, left: 0, bottom: -12, right: -12))

        initializeButtonCollection()
        buttonCollection!.edgeAnchors(leading: view.safeAreaLayoutGuide.leadingAnchor,
                                      bottom: view.safeAreaLayoutGuide.bottomAnchor,
                                      padding: UIEdgeInsets(top: 0, left: 12, bottom: -12, right: 0))
        buttonCollection!.dimensionAnchors(height: 500, width: 50)
        view.layoutIfNeeded()
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
        viewARSessionButton?.removeFromSuperview()
        endConnectSessionButton?.removeFromSuperview()
        buttonCollection?.removeFromSuperview()
        viewARSessionButton = nil
        endConnectSessionButton = nil
        buttonCollection = nil
        searchViewController = SearchTableViewController(viewModel: SearchTableViewModel())
        searchViewController!.delegate = self
        addChild(searchViewController!)
        view.addSubview(searchViewController!.view)
        searchViewController!.didMove(toParent: self)
        setupSubviewsAndChildVCs()
        arSessionVC = nil
        mapViewController.resetMap()
    }

    /// Segue into AR Connect session
    @objc private func startARSession() {
        guard let location = mapViewController.currentLocation else {
            createAndDisplayAlert(withTitle: "Error", body: "Current location is not available")
            return
        }
        if let arSessionVC = arSessionVC {
            present(arSessionVC, animated: true, completion: nil)
            return
        }
        switch mapViewController.shouldUseAlignment {
        case .gravity:
            createAndDisplayAlert(withTitle: "Poor Heading Accuracy",
                                  body: "Tap left and right side of the screen to adjust direction of True North")
            arSessionVC = ARSessionViewController(startLocation: location,
                                                  tripLocations: mapViewController.tripCoordinates.map { CLLocation(coordinate: $0) },
                                                  worldAlignment: .gravity)
        case .gravityAndHeading:
            arSessionVC = ARSessionViewController(startLocation: location,
                                                  tripLocations: mapViewController.tripCoordinates.map { CLLocation(coordinate: $0) },
                                                  worldAlignment: .gravityAndHeading)
        }

        mapViewController.viewModel.delegate = arSessionVC
        present(arSessionVC!, animated: true, completion: nil)
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
    func setUserDetailCardVisible(withModel userModel: UserCellModel) {
        cardDetailViewController = CardDetailViewController()
        addChild(cardDetailViewController!)
        view.addSubview(cardDetailViewController!.view)
        cardDetailViewController!.didMove(toParent: self)
        cardDetailViewController!.cellModel = userModel
//        cardDetailViewController!.userForCe
        cardDetailViewController!.delegate = self
        let scale = min(view.bounds.height/896.0, view.bounds.width/414.0)
        cardDetailViewController!.view.transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
        cardDetailViewController!.view.dimensionAnchors(height: cardDetailViewController!.view.bounds.height,
                                                        width: cardDetailViewController!.view.bounds.width)
        cardDetailViewController!.view.centerAnchors(centerX: view.centerXAnchor, centerY: view.centerYAnchor)
        cardDetailViewController!.view.alpha = 0
        view.updateConstraintsIfNeeded()
        UIView.animate(withDuration: 0.1) {
            self.cardDetailViewController!.view.alpha = 1
        }
    }
}

extension MainViewController: CardDetailDelegate {

    func removeFromHierarchy() {
        cardDetailViewController?.willMove(toParent: nil)
        cardDetailViewController?.view.removeFromSuperview()
        cardDetailViewController?.removeFromParent()
        cardDetailViewController = nil
    }

    func willSetMeetupLocation(withCellModel cellModel: UserCellModel) {
        searchViewController?.willMove(toParent: nil)
        searchViewController?.view.removeFromSuperview()
        searchViewController?.removeFromParent()
        searchViewController = nil
        navigationController?.navigationBar.isHidden = true

        mapViewController.willSetLocationMarker()

        mapViewController.meetupLocationObservable?
            .subscribe(onNext: { [weak self] location in
                guard let self = self else { return }
                self.navigationController?.navigationBar.isHidden = false
                self.handleSessionEnd()
                self.viewModel.requestToConnect(cellModel: cellModel, location: location)
            })
            .disposed(by: bag)
    }
}
