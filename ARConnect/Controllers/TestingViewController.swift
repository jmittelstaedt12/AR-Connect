//
//  TestingViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 1/17/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

class TestingViewController: UIViewController {

    let searchVC = SearchTableViewController()
    var childSearchVCTopConstraint: NSLayoutConstraint?
    var searchViewControllerPreviousYCoordinate: CGFloat?
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchVC.delegate = self
        let dummyUser = LocalUser()
        dummyUser.uid = "123"
        dummyUser.name = "TempName"
        dummyUser.email = "email@email.com"
        searchVC.users = [dummyUser, dummyUser, dummyUser, dummyUser, dummyUser, dummyUser, dummyUser, dummyUser, dummyUser, dummyUser, dummyUser]
        addChild(searchVC)
        view.addSubview(searchVC.view)
        searchVC.didMove(toParent: self)
        searchVC.view.edgeAnchors(leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4))
        childSearchVCTopConstraint = searchVC.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        searchVC.expansionState = .compressed
        setChildSearchVCState(toState: searchVC.expansionState)
        childSearchVCTopConstraint?.isActive = true
        searchVC.view.dimensionAnchors(height: 400)
    }

}

extension TestingViewController: SearchTableViewControllerDelegate {
    
    /// During pan of drawer VC, update child coordinates to match
    func updateCoordinatesDuringPan(to translationPoint: CGPoint, withVelocity velocity: CGPoint) {
        guard let previousYCoordinate = searchViewControllerPreviousYCoordinate, let topConstraint = childSearchVCTopConstraint else { return}
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
        guard let previousYCoordinate = searchViewControllerPreviousYCoordinate else { return }
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
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 4, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        })
        searchVC.view.isUserInteractionEnabled = true
    }
    
    //    /// Animate transition to expanded from compressed
    func animateToExpanded() {
        searchVC.expansionState = .expanded
        setChildSearchVCState(toState: searchVC.expansionState)
        animateTopConstraint()
    }
    
    /// Make card for tapped user visible in view
    func setChildUserDetailVCVisible(withUser user: LocalUser) {
//        let cardDetailVC = CardDetailViewController()
//        addChild(cardDetailVC)
//        view.addSubview(cardDetailVC.view)
//        cardDetailVC.didMove(toParent: self)
//        cardDetailVC.userForCell = user
//        cardDetailVC.delegate = self
//        cardDetailVC.view.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: UIEdgeInsets(top: 40, left: 40, bottom: -40, right: -40))
//        view.updateConstraintsIfNeeded()
    }
}
