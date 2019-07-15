//
//  SearchTableViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/31/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import RxSwift

protocol SearchTableViewControllerDelegate: class {
    func setUserDetailCardVisible(withModel userModel: UserCellModel)
}

final class SearchTableViewController: UIViewController, ControllerProtocol {

    typealias ViewModelType = SearchTableViewModel

    var viewModel: ViewModelType!

    weak var delegate: SearchTableViewControllerDelegate!
    private var searchItem: DispatchWorkItem?

    let disposeBag = DisposeBag()
    let searchText = PublishSubject<String?>()

    /// Read-only computed property for accessing MainView contents
    var searchTableView: SearchTableView {
        return view as! SearchTableView
    }

    override func loadView() {
        self.view = SearchTableView()
        searchTableView.setupView()
    }

    func configure(with viewModel: ViewModelType) {

        searchTableView.searchText.asObservable()
            .ignoreNil()
            .subscribe(viewModel.input.searchValue)
            .disposed(by: disposeBag)

        viewModel.output.reloadTableObservable
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.searchTableView.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        searchTableView.tableView.delegate = self
        searchTableView.tableView.dataSource = self
        let logoutButton = UIBarButtonItem(title: "Dismiss", style: .plain, target: self, action: #selector(dismissVC))
        navigationItem.setLeftBarButton(logoutButton, animated: true)
    }

    private func setupView() {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorConstants.primaryColor
        view.layer.cornerRadius = 5
    }

    @objc private func dismissVC() {
        dismiss(animated: true, completion: nil)
    }

}

// MARK: UITableViewDelegate Methods
extension SearchTableViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = viewModel.userCellModels?.count, count > 0 {
            searchTableView.restoreTableView()
        } else {
            searchTableView.emptyTableViewMessage()
        }
        return viewModel.userCellModels?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UserCell
        guard let cellModel = viewModel.userCellModels?[indexPath.row] else {
            return cell
        }
        cell.selectionStyle = .none
        cell.userCellModel = cellModel
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.panGestureRecognizer.isEnabled,
            let cell = tableView.cellForRow(at: indexPath) as? UserCell else { return }
        cell.isSelected = false
        delegate.setUserDetailCardVisible(withModel: cell.userCellModel)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if searchTableView.tableView.contentOffset.y == 0.0 {
            searchTableView.shouldHandleGesture = true
            searchTableView.tableView.panGestureRecognizer.isEnabled = false
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        searchTableView.shouldHandleGesture = true
    }
}
