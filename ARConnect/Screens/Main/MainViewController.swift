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

    // MARK: - Properties

    typealias ViewModelType = MainViewModel

    var viewModel: ViewModelType!

    private let bag = DisposeBag()

    private let connectNotificationName = Notification.Name(NotificationConstants.requestResponseNotificationKey)

    let mapViewController: MapViewController
    var searchViewController: SearchTableViewController?
    var arSessionViewController: ARSessionViewController?

    let logoutBarButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Log Out", for: .normal)
        btn.addTarget(self, action: #selector(AppDelegate.shared.rootViewController.switchToLogout), for: .touchUpInside)
        return btn
    }()

    let profileBarButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = .lightGray
        btn.setBackgroundImage(UIImage(named: "person-placeholder"), for: .normal)
        btn.layoutIfNeeded()
        btn.subviews.first?.contentMode = .scaleAspectFill
        btn.addTarget(self, action: #selector(didTapProfileImage), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.dimensionAnchors(height: 34, width: 34)
        btn.layer.cornerRadius = 17
        btn.layer.masksToBounds = true
        return btn
    }()

    var cardDetailViewController: CardDetailViewController?
    let disposeBag = DisposeBag()

    /// Read-only computed property for accessing MainView contents
    var mainView: MainView {
        return view as! MainView
    }

    // MARK: - Initialization

    init(viewModel: ViewModelType) {
        self.viewModel = viewModel
        self.mapViewController = MapViewController(viewModel: MapViewModel(uid: viewModel.uid))
        self.searchViewController = SearchTableViewController(viewModel: SearchTableViewModel())
        super.init(nibName: nil, bundle: nil)
        searchViewController?.delegate = self
        configureChildVCs()
        configure(with: viewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = MainView(mapView: mapViewController.view, searchView: (searchViewController!.view as! SearchTableView))
        searchViewController!.searchTableView.delegate = mainView
        mainView.mainDelegate = self
        mainView.mapDelegate = mapViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBarItems()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        mainView.setupView()
    }

    private func configureChildVCs() {
        addChild(mapViewController)
        mapViewController.didMove(toParent: self)
        guard let searchVC = searchViewController else { return }
        addChild(searchVC)
        searchVC.didMove(toParent: self)
    }

    func configure(with viewModel: ViewModelType) {

        // ViewModel inputs
        logoutBarButton.rx.tap.asObservable()
            .subscribe(viewModel.input.logoutRequest)
            .disposed(by: disposeBag)

        // ViewModel outputs
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
                        searchVC.searchTableView.expansionState = .compressed
                        self?.mainView.animateTopConstraint()
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

    private func setupNavigationBarItems() {
        let titleView = UILabel()
        titleView.text = "AR Connect"
        titleView.textColor = .white
        navigationItem.titleView = titleView
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: logoutBarButton)
        navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: profileBarButton)]
    }

    @objc private func didTapProfileImage() {

    }

    /// When connect to user, transition into AR Session state
    private func handleSessionStart() {
        searchViewController?.willMove(toParent: nil)
        searchViewController?.removeFromParent()
        searchViewController = nil

        mainView.startARSessionButton = ARSessionButton(type: .system)

        mainView.endConnectSessionButton = ARSessionButton(type: .system)
        mainView.endConnectSessionButton!.rx.tap.asObservable()
            .subscribe(viewModel.input.disconnectRequest)
            .disposed(by: disposeBag)

        mainView.handleSessionStart()
    }

    @objc private func handleSessionEnd() {

        mainView.handleSessionEnd()
        searchViewController = SearchTableViewController(viewModel: SearchTableViewModel())
        searchViewController!.delegate = self
        addChild(searchViewController!)
        view.addSubview(searchViewController!.view)
        searchViewController!.didMove(toParent: self)
        arSessionViewController = nil
        mapViewController.resetMap()
    }

}

extension MainViewController: SearchTableViewControllerDelegate {

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

extension MainViewController: MainViewSessionDelegate {

    /// Segue into AR Connect session
    func startARSession() {
        guard let location = mapViewController.currentLocation else {
            createAndDisplayAlert(withTitle: "Error", body: "Current location is not available")
            return
        }
        if let arSessionVC = arSessionViewController {
            present(arSessionVC, animated: true, completion: nil)
            return
        }
        switch mapViewController.shouldUseAlignment {
        case .gravity:
            createAndDisplayAlert(withTitle: "Poor Heading Accuracy",
                                  body: "Tap left and right side of the screen to adjust direction of True North")
            arSessionViewController = ARSessionViewController(startLocation: location,
                                                              tripLocations: mapViewController.tripCoordinates.map { CLLocation(coordinate: $0) },
                                                              worldAlignment: .gravity)
        case .gravityAndHeading:
            arSessionViewController = ARSessionViewController(startLocation: location,
                                                              tripLocations: mapViewController.tripCoordinates.map { CLLocation(coordinate: $0) },
                                                              worldAlignment: .gravityAndHeading)
        }

        mapViewController.viewModel.delegate = arSessionViewController
        present(arSessionViewController!, animated: true, completion: nil)
    }

    func endConnectSession() {

    }
}
