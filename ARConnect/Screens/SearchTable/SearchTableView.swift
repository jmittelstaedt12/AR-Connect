//
//  SearchTableView.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 7/10/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import RxSwift

protocol SearchTableViewDelegate: class {
    func updateCoordinatesDuringPan(to translationPoint: CGPoint, withVelocity velocity: CGPoint)
    func updateCoordinatesAfterPan(to translationPoint: CGPoint, withVelocity velocity: CGPoint)
    func animateToExpanded()
}

class SearchTableView: UIView {

    var panGestureRecognizer: UIPanGestureRecognizer?

    weak var delegate: SearchTableViewDelegate!

    let drawerIconView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 1.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let userSearchBar: UISearchBar = {
        let searchBar = UISearchBar()
        let textField = searchBar.value(forKey: "searchField") as! UITextField
        searchBar.placeholder = "Find a friend"
        searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.layer.cornerRadius = 5
        return searchBar
    }()

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = 63.5
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "userCell")
        tableView.bounces = false
        tableView.alpha = 0.0
        return tableView
    }()

    enum ExpansionState: CGFloat {
        case expanded
        case compressed
    }
    var shouldHandleGesture: Bool = true
    var expansionState: ExpansionState = .compressed

    let searchText = PublishSubject<String?>()

    func setupView() {
        userSearchBar.delegate = self
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ColorConstants.primaryColor
        layer.cornerRadius = 5

        addSubviews()
        setSubviewAutoLayoutConstraints()
        setupPanGestureRecognizer()
    }

    private func addSubviews() {
        addSubview(drawerIconView)
        addSubview(userSearchBar)
        addSubview(tableView)
    }

    /// Setup auto layout anchors, dimensions, and other position properties for subviews
    private func setSubviewAutoLayoutConstraints() {
        drawerIconView.edgeAnchors(top: topAnchor, padding: UIEdgeInsets(top: 6, left: 0, bottom: 0, right: 0))
        drawerIconView.centerAnchors(centerX: centerXAnchor)
        drawerIconView.dimensionAnchors(height: 3, width: 32)

        userSearchBar.edgeAnchors(top: drawerIconView.bottomAnchor,
                                  leading: leadingAnchor,
                                  trailing: trailingAnchor,
                                  padding: UIEdgeInsets(top: 6, left: 10, bottom: 0, right: -10))
        userSearchBar.dimensionAnchors(height: 30)

        tableView.edgeAnchors(top: userSearchBar.bottomAnchor,
                              leading: leadingAnchor,
                              bottom: bottomAnchor,
                              trailing: trailingAnchor,
                              padding: UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0))
    }

    /// Configure pan gesture recognizer for use in MainViewController
    private func setupPanGestureRecognizer() {
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(onSearchViewControllerPan(sender:)))
        panGR.cancelsTouchesInView = false
        panGR.delegate = self
        self.panGestureRecognizer = panGR
        addGestureRecognizer(panGestureRecognizer!)
    }

    /// Run on child instance of SearchViewController pan gesture
    @objc private func onSearchViewControllerPan(sender: UIPanGestureRecognizer) {
        guard shouldHandleGesture else { return }
        let translationPoint = sender.translation(in: superview)
        let velocity = sender.velocity(in: superview)
        switch sender.state {
        case .changed:
            delegate.updateCoordinatesDuringPan(to: translationPoint, withVelocity: velocity)
        case .ended:
            delegate.updateCoordinatesAfterPan(to: translationPoint, withVelocity: velocity)
            tableView.panGestureRecognizer.isEnabled = true
        default:
            return
        }
    }

    func emptyTableViewMessage() {
        let viewRect = CGRect(origin: CGPoint(x: 0, y: 0),
                              size: CGSize(width: frame.size.width,
                                           height: frame.size.height))
        let backgroundView = UIView(frame: viewRect)
        let emptyMessageLabel = UILabel()
        backgroundView.addSubview(emptyMessageLabel)
        emptyMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyMessageLabel.edgeAnchors(top: backgroundView.topAnchor, padding: UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0))
        emptyMessageLabel.centerAnchors(centerX: backgroundView.centerXAnchor)
        emptyMessageLabel.dimensionAnchors(width: 260)
        emptyMessageLabel.text = "Try searching for a friend by first name"
        emptyMessageLabel.textAlignment = .center
        emptyMessageLabel.textColor = .darkGray
        emptyMessageLabel.font = emptyMessageLabel.font.withSize(16)
        emptyMessageLabel.numberOfLines = 0
        emptyMessageLabel.sizeToFit()
        backgroundView.backgroundColor = UIColor(red: 234, green: 234, blue: 234)
        tableView.backgroundView = backgroundView
        tableView.separatorStyle = .none
    }

    func restoreTableView() {
        tableView.backgroundView = nil
        tableView.separatorStyle = .singleLine
    }
}

// MARK: UIGestureRecognizerDelegate Methods
extension SearchTableView: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = panGestureRecognizer.velocity(in: superview)
        tableView.panGestureRecognizer.isEnabled = true
        if otherGestureRecognizer == tableView.panGestureRecognizer {
            switch expansionState {
            case .compressed:
                return false
            case .expanded:
                if velocity.y > 0.0 {
                    if tableView.contentOffset.y > 0.0 {
                        shouldHandleGesture = false
                        return true
                    }
                    shouldHandleGesture = true
                    tableView.panGestureRecognizer.isEnabled = false
                    return false
                } else {
                    shouldHandleGesture = false
                    return true
                }
            }
        }
        return false
    }
}

// MARK: UITextFieldDelegate Methods
extension SearchTableView: UISearchBarDelegate {

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        delegate.animateToExpanded()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText.onNext(searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.userSearchBar.endEditing(true)
    }
}
