//
//  MainView.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 7/10/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

protocol MainViewSessionDelegate: AnyObject {
    func startARSession()
    func endConnectSession()
}

protocol MainViewMapDelegate: AnyObject {
    func centerAtLocation()
    func centerAtPath()
}

final class MainView: UIView {

    var startARSessionButton: ARSessionButton? {
        willSet {
            guard let btn = newValue else { return }
            btn.setTitle("AR", for: .normal)
            btn.layer.cornerRadius = 30
            btn.dimensionAnchors(height: 60, width: 60)
            addSubview(btn)
        }
    }

    var endConnectSessionButton: ARSessionButton? {
        willSet {
            guard let btn = newValue else { return }
            btn.setTitle("End", for: .normal)
            btn.layer.cornerRadius = 30
            btn.dimensionAnchors(height: 60, width: 60)
            addSubview(btn)
        }
    }

    let mapView: UIView
    let searchView: SearchTableView?
    private var expandedHeight: CGFloat!
    private var compressedHeight: CGFloat!
    private var compressedYCoordinate: CGFloat!
    private var expandedYCoordinate: CGFloat!

    var childSearchVCTopConstraint: NSLayoutConstraint?
    var childSearchVCHeightConstraint: NSLayoutConstraint?
    var searchViewControllerPreviousYCoordinate: CGFloat?

    weak var mainDelegate: MainViewSessionDelegate?
    weak var mapDelegate: MainViewMapDelegate?

    var buttonCollection: CollapsibleCollectionView?

    // MARK: - Init Methods

    init(mapView: UIView, searchView: SearchTableView) {
        self.mapView = mapView
        self.searchView = searchView
        super.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported.")
    }

    // MARK: - Methods

    private func setChildSearchVCState(toState state: SearchTableView.ExpansionState) {
        guard let topConstraint = childSearchVCTopConstraint else {
            return
        }
        switch state {
        case .compressed:
            topConstraint.constant = -compressedHeight
            searchViewControllerPreviousYCoordinate = bounds.height - compressedHeight
        case .expanded:
            topConstraint.constant = -expandedHeight
            searchViewControllerPreviousYCoordinate = bounds.height - expandedHeight
        }
    }

    func handleSessionStart() {
        searchView?.removeFromSuperview()
        guard let viewARSessionButton = startARSessionButton,
            let endConnectSessionButton = endConnectSessionButton else { return }
        viewARSessionButton.edgeAnchors(bottom: mapView.bottomAnchor,
                                         trailing: mapView.trailingAnchor,
                                         padding: UIEdgeInsets(top: 0, left: 0, bottom: -12, right: -12))
        viewARSessionButton.addTarget(self, action: #selector(startARSession), for: .touchUpInside)

        // Setup auto layout anchors for endConnectSession button
        endConnectSessionButton.edgeAnchors(bottom: viewARSessionButton.topAnchor,
                                             trailing: mapView.trailingAnchor,
                                             padding: UIEdgeInsets(top: 0, left: 0, bottom: -12, right: -12))
        endConnectSessionButton.addTarget(self, action: #selector(endConnectSession), for: .touchUpInside)

        initializeButtonCollection()

        layoutIfNeeded()
    }

    func handleSessionEnd() {
        startARSessionButton?.removeFromSuperview()
        endConnectSessionButton?.removeFromSuperview()
        buttonCollection?.removeFromSuperview()
        startARSessionButton = nil
        endConnectSessionButton = nil
        buttonCollection = nil
    }

    private func initializeButtonCollection() {
        let centerLocationButton = UIButton()
        centerLocationButton.setTitle("Center", for: .normal)
        centerLocationButton.setTitleColor(.black, for: .normal)
        centerLocationButton.addTarget(self, action: #selector(centerAtLocation), for: .touchUpInside)
        let centerPathButton = UIButton()
        centerPathButton.setTitle("Path", for: .normal)
        centerPathButton.setTitleColor(.black, for: .normal)
        centerPathButton.addTarget(self, action: #selector(centerAtPath), for: .touchUpInside)
        buttonCollection = CollapsibleCollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout(),
                                                     collapsed: true, buttons: [centerLocationButton, centerPathButton], growDirection: .fromBottom)
        addSubview(buttonCollection!)
        buttonCollection!.edgeAnchors(leading: safeAreaLayoutGuide.leadingAnchor,
                                      bottom: safeAreaLayoutGuide.bottomAnchor,
                                      padding: UIEdgeInsets(top: 0, left: 12, bottom: -12, right: 0))
        buttonCollection!.dimensionAnchors(height: 500, width: 50)
    }

    @objc private func startARSession() {
        mainDelegate?.startARSession()
    }

    @objc private func endConnectSession() {
        mainDelegate?.endConnectSession()
    }

    @objc private func centerAtLocation() {
        mapDelegate?.centerAtLocation()
    }

    @objc private func centerAtPath() {
        mapDelegate?.centerAtPath()
    }
}

extension MainView: ProgrammaticUI {
    func setupView() {
        searchView?.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        searchView?.translatesAutoresizingMaskIntoConstraints = false
        expandedHeight = (2*frame.height)/5
        compressedHeight = 50
        compressedYCoordinate = frame.height - compressedHeight
        expandedYCoordinate = frame.height - expandedHeight
        backgroundColor = .white

        addSubviews()
        setSubviewAutoLayoutConstraints()
        hideKeyboardWhenTappedAround()
    }

    /// Add all subviews and child view controllers to main view controller
    func addSubviews() {
        addSubview(mapView)
        addSubview(searchView!)
    }

    /// Setup auto layout anchors, dimensions, and other position properties for subviews
    func setSubviewAutoLayoutConstraints() {

        // Setup auto layout anchors for map view
        mapView.edgeAnchors(top: topAnchor,
                            leading: leadingAnchor,
                            bottom: bottomAnchor,
                            trailing: trailingAnchor)

        // Setup auto layout anchors for searchViewController
        guard let searchView = searchView else { return }
        searchView.edgeAnchors(leading: safeAreaLayoutGuide.leadingAnchor,
                               trailing: safeAreaLayoutGuide.trailingAnchor,
                               padding: UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4))

        childSearchVCTopConstraint = searchView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: 0)
        childSearchVCTopConstraint?.isActive = true
        childSearchVCHeightConstraint = searchView.heightAnchor.constraint(equalToConstant: expandedHeight + safeAreaInsets.bottom)
        childSearchVCHeightConstraint?.isActive = true
        searchView.expansionState = .compressed
        setChildSearchVCState(toState: searchView.expansionState)
    }
}

extension MainView: SearchTableViewDelegate {

    /// During pan of drawer VC, update child coordinates to match
    func updateCoordinatesDuringPan(to translationPoint: CGPoint, withVelocity velocity: CGPoint) {
        guard let searchView = searchView,
            let previousYCoordinate = searchViewControllerPreviousYCoordinate,
            let topConstraint = childSearchVCTopConstraint else { return }
        let constraintOffset = previousYCoordinate - frame.height
        let newTopConstraint = previousYCoordinate + translationPoint.y
        if newTopConstraint >= expandedYCoordinate && newTopConstraint <= compressedYCoordinate + 40 {
            topConstraint.constant = constraintOffset + translationPoint.y
        } else if newTopConstraint <= expandedYCoordinate && newTopConstraint >= expandedYCoordinate - 40 {
            expandedHeight += abs(newTopConstraint - expandedYCoordinate)
        }
        searchView.tableView.alpha = (1.0/(-expandedHeight)) * topConstraint.constant
        searchView.isUserInteractionEnabled = false
    }

    /// When release pan, update coordinates to compressed or expanded depending on velocity
    func updateCoordinatesAfterPan(to translationPoint: CGPoint, withVelocity velocity: CGPoint) {
        guard let searchView = searchView, let previousYCoordinate = searchViewControllerPreviousYCoordinate else { return }
        expandedHeight = (2*frame.height)/5
        let newTopConstraint = previousYCoordinate + translationPoint.y
        let compressedYCoordinate = frame.height - compressedHeight
        let expandedYCoordinate = frame.height - expandedHeight
        let velocityThreshold: CGFloat = 100
        if abs(velocity.y) < velocityThreshold {
            if previousYCoordinate == compressedYCoordinate {
                if newTopConstraint <= compressedYCoordinate-125 {
                    searchView.expansionState = .expanded
                } else {
                    searchView.expansionState = .compressed
                }
            } else {
                if newTopConstraint >= expandedYCoordinate + 125 {
                    searchView.expansionState = .compressed
                } else {
                    searchView.expansionState = .expanded
                }
            }

        } else {
            if previousYCoordinate == compressedYCoordinate {
                if newTopConstraint <= compressedYCoordinate {
                    searchView.expansionState = .expanded
                } else {
                    searchView.expansionState = .compressed
                }
            } else {
                if newTopConstraint >= expandedYCoordinate {
                    searchView.expansionState = .compressed
                } else {
                    searchView.expansionState = .expanded
                }
            }
        }
        setChildSearchVCState(toState: searchView.expansionState)
        animateTopConstraint()
    }

    /// Animate transition to compressed or expanded and make view interactive again
    func animateTopConstraint() {
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 4, options: .curveEaseOut, animations: { [weak self] in
                guard let self = self, let searchView = self.searchView else { return }
                searchView.tableView.alpha = (searchView.expansionState == .compressed) ? 0.0 : 1.0
                self.layoutIfNeeded()
            })
        searchView?.isUserInteractionEnabled = true
    }

    /// Animate transition to expanded from compressed
    func animateToExpanded() {
        guard let searchView = searchView else { return }
        searchView.expansionState = .expanded
        setChildSearchVCState(toState: searchView.expansionState)
        animateTopConstraint()
    }
}
