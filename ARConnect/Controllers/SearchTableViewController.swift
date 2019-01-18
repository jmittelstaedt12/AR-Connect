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
    func setChildUserDetailVCVisible(withUser user: LocalUser)
}

final class SearchTableViewController: UIViewController {
    
    weak var delegate: SearchTableViewControllerDelegate!
    var users: [LocalUser]?
    var panGestureRecognizer: UIPanGestureRecognizer?
    
    let bag = DisposeBag()
    
    let drawerIconView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.gray
        view.layer.cornerRadius = 1.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let searchUsersTextField: UITextField = {
        let tf = UITextField()
        tf.backgroundColor = .white
        tf.placeholder = "Find a friend"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.layer.borderColor = UIColor.black.cgColor
        tf.layer.cornerRadius = 5
        return tf
    }()
    
    let tableView: UITableView = {
        let tb = UITableView()
        tb.rowHeight = 63.5
        tb.translatesAutoresizingMaskIntoConstraints = false
        tb.bounces = false
        return tb
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
        FirebaseClient.fetchObservableUsers().subscribe(onNext: { [weak self] fetchedUsers in
            self?.users = fetchedUsers
            self?.tableView.reloadData()
        }, onError: { [weak self] error in
            self?.createAndDisplayAlert(withTitle: "Error", body: error.localizedDescription)
        }).disposed(by: bag)
        view.addSubview(drawerIconView)
        searchUsersTextField.delegate = self
        view.addSubview(searchUsersTextField)
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
        view.backgroundColor = UIColor(white: 5/6, alpha: 1.0)
        view.layer.cornerRadius = 5
    }
    
    /// Configure pan gesture recognizer for use in MainViewController
    private func setupPanGestureRecognizer(){
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
    private func setupViews(){
        drawerIconView.edgeAnchors(top: view.topAnchor, padding: UIEdgeInsets(top: 6, left: 00, bottom: 0, right: 0))
        drawerIconView.centerAnchors(centerX: view.centerXAnchor)
        drawerIconView.dimensionAnchors(height: 3, width: 32)
        searchUsersTextField.edgeAnchors(top: drawerIconView.bottomAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor, padding: UIEdgeInsets(top: 6, left: 10, bottom: 0, right: -10))
        searchUsersTextField.dimensionAnchors(height: 30)
        tableView.edgeAnchors(top: searchUsersTextField.bottomAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor, padding: UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0))
    }
    
    /// If user taps on text field from compressed, expand before editing
    func textFieldDidBeginEditing(_ textField: UITextField) {
            delegate.animateToExpanded()
        }
    
    @objc private func dismissVC(){
        dismiss(animated: true, completion: nil)
    }
}


extension SearchTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UserTableViewCell
        guard let user = users?[indexPath.row] else {
            return cell
        }
        cell.selectionStyle = .none
        cell.nameLabel.text = user.name
        cell.usernameLabel.text = user.email
        cell.profileImageView.image = UIImage(named: "person-placeholder")
        guard let url = user.profileUrl else { return cell }
        NetworkRequests.profilePictureNetworkRequest(withUrl: url) { (data) in
            DispatchQueue.main.async {
                cell.profileImageView.image = UIImage(data: data)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.panGestureRecognizer.isEnabled, let cell = tableView.cellForRow(at: indexPath) as? UserTableViewCell, let email = cell.usernameLabel, let user = users?.first(where: {$0.email == email.text}) else { return }
        cell.isSelected = false
        delegate.setChildUserDetailVCVisible(withUser: user)
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

extension SearchTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
    }
}

class UserCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
