//
//  SearchTableViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/31/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase

class SearchTableViewController: UIViewController {

    var users: [LocalUser]?
    let cellId = "cellId"

    let searchUsersTextField: UITextField = {
        let tf = UITextField()
        tf.backgroundColor = .white
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.layer.borderWidth = 2
        tf.layer.borderColor = UIColor.black.cgColor
        tf.layer.cornerRadius = 5
        return tf
    }()
    
    let tableView: UITableView = {
        let tb = UITableView()
        tb.translatesAutoresizingMaskIntoConstraints = false
        return tb
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FirebaseClient.fetchUsers(closure: { fetchedUsers in
            self.users = fetchedUsers
            self.tableView.reloadData()
        })
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        view.addSubview(searchUsersTextField)
        view.addSubview(tableView)
        setupViews()
        let logoutButton = UIBarButtonItem(title: "Dismiss", style: .plain, target: self, action: #selector(dismissVC))
        navigationItem.setLeftBarButton(logoutButton, animated: true)
    }
    
    private func setupViews(){
        searchUsersTextField.edgeAnchors(top: view.topAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor, padding: UIEdgeInsets(top: 30, left: 0, bottom: 0, right: 0))
        searchUsersTextField.dimensionAnchors(height: 30)
        tableView.edgeAnchors(top: searchUsersTextField.bottomAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor, padding: UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0))
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
        let cellDetailVC = CellDetailViewController()
        cellDetailVC.user = user
        self.navigationController?.pushViewController(cellDetailVC, animated: true)
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

extension SearchTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
    }
}
