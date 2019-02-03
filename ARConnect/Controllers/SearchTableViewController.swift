//
//  SearchTableViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/31/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase
import RxSwift

protocol SearchTableViewControllerDelegate: class {
    func updateCoordinatesDuringPan(to translationPoint: CGPoint, withVelocity velocity: CGPoint)
    func updateCoordinatesAfterPan(to translationPoint: CGPoint, withVelocity velocity: CGPoint)
    func animateToExpanded()
    func setUserDetailCardVisible(withUser user: LocalUser)
}

final class SearchTableViewController: UIViewController {

    weak var delegate: SearchTableViewControllerDelegate!
    var users: [LocalUser]?
    var panGestureRecognizer: UIPanGestureRecognizer?
    private var searchItem: DispatchWorkItem?
    let bag = DisposeBag()

    let drawerIconView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.gray
        view.layer.cornerRadius = 1.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let userSearchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.backgroundColor = .white
        searchBar.placeholder = "Find a friend"
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.layer.borderColor = UIColor.black.cgColor
        searchBar.layer.cornerRadius = 5
        return searchBar
    }()

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = 63.5
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.bounces = false
        return tableView
    }()

    enum ExpansionState: CGFloat {
        case expanded
        case compressed
    }
    private var shouldHandleGesture: Bool = true
    var expansionState = ExpansionState.compressed

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
//        setObservers()
        view.addSubview(drawerIconView)
        userSearchBar.delegate = self
        view.addSubview(userSearchBar)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "UserTableViewCell", bundle: nil), forCellReuseIdentifier: "userCell")
        view.addSubview(tableView)
        setupPanGestureRecognizer()
        setupViews()
        let logoutButton = UIBarButtonItem(title: "Dismiss", style: .plain, target: self, action: #selector(dismissVC))
        navigationItem.setLeftBarButton(logoutButton, animated: true)
    }

    private func setupView() {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 5 / 6, alpha: 1.0)
        view.layer.cornerRadius = 5
    }

    private func setObservers() {
        FirebaseClient.fetchObservableUsers(withObservableType: .continuous).subscribe(onNext: { [weak self] fetchedUsers in
            self?.users = fetchedUsers
            self?.tableView.reloadData()
            }, onError: { [weak self] error in
                self?.createAndDisplayAlert(withTitle: "Error", body: error.localizedDescription)
        }).disposed(by: bag)
    }

    /// Configure pan gesture recognizer for use in MainViewController
    private func setupPanGestureRecognizer() {
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(onSearchViewControllerPan(sender:)))
        panGR.cancelsTouchesInView = false
        panGR.delegate = self
        self.panGestureRecognizer = panGR
        view.addGestureRecognizer(panGestureRecognizer!)
    }

    /// Run on child instance of SearchViewController pan gesture
    @objc private func onSearchViewControllerPan(sender: UIPanGestureRecognizer) {
        guard shouldHandleGesture else { return }
        let translationPoint = sender.translation(in: view.superview)
        let velocity = sender.velocity(in: view.superview)
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

    /// Set dimensions and constraints for subviews
    private func setupViews() {
        drawerIconView.edgeAnchors(top: view.topAnchor, padding: UIEdgeInsets(top: 6, left: 00, bottom: 0, right: 0))
        drawerIconView.centerAnchors(centerX: view.centerXAnchor)
        drawerIconView.dimensionAnchors(height: 3, width: 32)
        userSearchBar.edgeAnchors(top: drawerIconView.bottomAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor, padding: UIEdgeInsets(top: 6, left: 10, bottom: 0, right: -10))
        userSearchBar.dimensionAnchors(height: 30)
        tableView.edgeAnchors(top: userSearchBar.bottomAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor, padding: UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0))
    }

    /// If user taps on text field from compressed, expand before editing
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate.animateToExpanded()
    }

    @objc private func dismissVC() {
        dismiss(animated: true, completion: nil)
    }

}

// MARK: UITableViewDelegate Methods
extension SearchTableViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UserTableViewCell
        guard var user = users?[indexPath.row] else {
            return cell
        }
        cell.selectionStyle = .none
        cell.nameLabel.text = user.name
        cell.usernameLabel.text = user.email
        if user.isOnline { cell.isOnlineImageView.backgroundColor = .green }
        guard let url = user.profileUrl else {
            cell.profileImageView.image = UIImage(named: "person-placeholder")
            return cell
        }
        if let image = user.profileImage {
            cell.profileImageView.image = image
            return cell
        }
        NetworkRequests.profilePictureNetworkRequest(withUrl: url) { (data) in
            DispatchQueue.main.async {
                user.profileImage = UIImage(data: data)
                cell.profileImageView.image = user.profileImage
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.panGestureRecognizer.isEnabled, let cell = tableView.cellForRow(at: indexPath) as? UserTableViewCell, let email = cell.usernameLabel, let user = users?.first(where: { $0.email == email.text }) else { return }
        cell.isSelected = false
        delegate.setUserDetailCardVisible(withUser: user)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if tableView.contentOffset.y == 0.0 {
            shouldHandleGesture = true
            tableView.panGestureRecognizer.isEnabled = false
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        shouldHandleGesture = true
    }
}

// MARK: UIGestureRecognizerDelegate Methods
extension SearchTableViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = panGestureRecognizer.velocity(in: view.superview)
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
extension SearchTableViewController: UISearchBarDelegate {

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        delegate.animateToExpanded()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchItem?.cancel()
        guard !searchText.isEmpty else {
            users = []
            tableView.reloadData()
            return
        }
        let newWorkItem = DispatchWorkItem {
            let query = FirebaseClient.usersRef.queryOrdered(byChild: "name").queryStarting(atValue: searchText).queryEnding(atValue: searchText+"\u{f8ff}")
            FirebaseClient.fetchObservableUsers(withObservableType: .singleEvent, queryReference: query).subscribe(onNext: { [weak self] fetchedUsers in
                self?.users = fetchedUsers
                self?.tableView.reloadData()
            }).disposed(by: self.bag)
        }
        searchItem = newWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250), execute: newWorkItem)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    }

}
