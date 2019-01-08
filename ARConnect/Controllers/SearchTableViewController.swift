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

final class SearchTableViewController: UIViewController, UIGestureRecognizerDelegate {
    
    weak var delegate: SearchTableViewControllerDelegate!
    var users: [LocalUser]?
    
    let bag = DisposeBag()
    let cellId = "cellId"

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
        tb.translatesAutoresizingMaskIntoConstraints = false
        tb.alwaysBounceVertical = false
        return tb
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
//        FirebaseClient.fetchUsers(handler: { fetchedUsers in
//            self.users = fetchedUsers
//            self.tableView.reloadData()
//        })
        
        FirebaseClient.fetchObservableUsers().subscribe(onNext: { (fetchedUsers) in
            self.users = fetchedUsers
            self.tableView.reloadData()
        }, onError: { (error) in
            self.createAndDisplayAlert(withTitle: "Error", body: error.localizedDescription)
        }).disposed(by: bag)
        
        view.addSubview(drawerIconView)
        searchUsersTextField.delegate = self
        view.addSubview(searchUsersTextField)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
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
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onSearchViewControllerPan(sender:)))
        panGestureRecognizer.cancelsTouchesInView = false
        panGestureRecognizer.delegate = self
        self.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    /// Run on child instance of SearchViewController pan gesture
    @objc private func onSearchViewControllerPan(sender: UIPanGestureRecognizer) {
        let translationPoint = sender.translation(in: view.superview)
        let velocity = sender.velocity(in: view.superview)
        switch sender.state {
        case .changed:
            delegate.updateCoordinatesDuringPan(to: translationPoint, withVelocity: velocity)
        case .ended:
            delegate.updateCoordinatesAfterPan(to: translationPoint, withVelocity: velocity)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        guard let user = users?[indexPath.row] else{
            return cell
        }
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath), let email = cell.detailTextLabel, let user = users?.first(where: {$0.email == email.text}) else{
            return;
        }
        cell.isSelected = false
        delegate.setChildUserDetailVCVisible(withUser: user)
    }
}

extension SearchTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
    }
}

extension SearchTableViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 0 {
            onSearchViewControllerPan(sender: scrollView.panGestureRecognizer)
        }
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
