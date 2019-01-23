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
    var childSearchVCHeightConstraint: NSLayoutConstraint?
    var searchViewControllerPreviousYCoordinate: CGFloat?
   
    var expandedHeight: CGFloat = 400 {
        willSet {
            childSearchVCHeightConstraint?.constant = newValue
            childSearchVCTopConstraint?.constant = -newValue
        }
    }
    let compressedHeight: CGFloat = 50
    
    private func setChildSearchVCState(toState state: SearchTableViewController.ExpansionState) {
        guard let tc = childSearchVCTopConstraint else {
            return
        }
        switch state {
        case .compressed:
            tc.constant = -50
            searchViewControllerPreviousYCoordinate = view.bounds.height - compressedHeight
        case .expanded:
            tc.constant = -400
            searchViewControllerPreviousYCoordinate = view.bounds.height - expandedHeight
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchVC.delegate = self
        let dummyUser = LocalUser()
        dummyUser.uid = "123"
        dummyUser.name = "TempName"
        dummyUser.email = "email@email.com"
        dummyUser.isOnline = true
        searchVC.users = [dummyUser, dummyUser, dummyUser, dummyUser, dummyUser, dummyUser, dummyUser, dummyUser, dummyUser, dummyUser, dummyUser]
        addChild(searchVC)
        view.addSubview(searchVC.view)
        searchVC.didMove(toParent: self)
        searchVC.view.edgeAnchors(leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4))
        childSearchVCTopConstraint = searchVC.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        childSearchVCHeightConstraint = searchVC.view.heightAnchor.constraint(equalToConstant: expandedHeight)
        childSearchVCTopConstraint?.isActive = true
        childSearchVCHeightConstraint?.isActive = true
        searchVC.expansionState = .compressed
        setChildSearchVCState(toState: searchVC.expansionState)
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
        print(expandedYCoordinate, newTopConstraint)
        if newTopConstraint >= expandedYCoordinate && newTopConstraint <= compressedYCoordinate + 40 {
            topConstraint.constant = constraintOffset+translationPoint.y
        }
        else if newTopConstraint < expandedYCoordinate && newTopConstraint >= expandedYCoordinate - 40 {
            print("value difference: \(abs(newTopConstraint - expandedYCoordinate))")
            expandedHeight = 400 + abs(newTopConstraint - expandedYCoordinate)
        }
        searchVC.view.isUserInteractionEnabled = false
    }
    
    /// When release pan, update coordinates to compressed or expanded depending on velocity
    func updateCoordinatesAfterPan(to translationPoint: CGPoint, withVelocity velocity: CGPoint) {
        guard let previousYCoordinate = searchViewControllerPreviousYCoordinate else { return }
        expandedHeight = 400
        let newTopConstraint = previousYCoordinate + translationPoint.y
        let compressedYCoordinate = view.frame.height-50
        let expandedYCoordinate = view.frame.height-400
        let velocityThreshold: CGFloat = 100
        if abs(velocity.y) < velocityThreshold {
            if previousYCoordinate == compressedYCoordinate {
                if newTopConstraint <= compressedYCoordinate-125 {
                    searchVC.expansionState = .expanded
                } else {
                    searchVC.expansionState = .compressed
                }
            } else {
                if newTopConstraint >= expandedYCoordinate+125 {
                    searchVC.expansionState = .compressed
                } else {
                    searchVC.expansionState = .expanded
                }
            }
            
        } else {
            if previousYCoordinate == compressedYCoordinate {
                if velocity.y < 0 {
                    searchVC.expansionState = .expanded
                } else {
                    searchVC.expansionState = .compressed
                }
            } else {
                if velocity.y > 0 {
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
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 4, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        })
        searchVC.view.isUserInteractionEnabled = true
    }
    
    
    /// Animate transition to expanded from compressed
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
