//
//  SearchTableViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/31/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import RxSwift

final class SearchTableViewController: UIViewController, ControllerProtocol {

    typealias ViewModelType = SearchTableViewModel

    var viewModel: ViewModelType!

    weak var delegate: SearchTableViewControllerDelegate!
//    var users: [LocalUser]?
    var panGestureRecognizer: UIPanGestureRecognizer?
    private var searchItem: DispatchWorkItem?

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
        tableView.bounces = false
        tableView.alpha = 0.0
        return tableView
    }()

    enum ExpansionState: CGFloat {
        case expanded
        case compressed
    }
    private var shouldHandleGesture: Bool = true
    var expansionState: ExpansionState = .compressed

    let disposeBag = DisposeBag()
    let searchText = PublishSubject<String?>()

    func configure(with viewModel: ViewModelType) {

        searchText.asObservable()
            .ignoreNil()
            .subscribe(viewModel.input.searchValue)
            .disposed(by: disposeBag)

        viewModel.output.reloadTableObservable
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }

    static func create(with viewModel: ViewModelType) -> UIViewController {
        let controller = SearchTableViewController()
        controller.viewModel = viewModel
        controller.configure(with: controller.viewModel)
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        view.addSubview(drawerIconView)
        userSearchBar.delegate = self
        view.addSubview(userSearchBar)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "userCell")
        view.addSubview(tableView)
        setupPanGestureRecognizer()
        setupViews()
        let logoutButton = UIBarButtonItem(title: "Dismiss", style: .plain, target: self, action: #selector(dismissVC))
        navigationItem.setLeftBarButton(logoutButton, animated: true)
    }

    private func setupView() {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorConstants.primaryColor
        view.layer.cornerRadius = 5
    }

    /// Set dimensions and constraints for subviews
    private func setupViews() {
        drawerIconView.edgeAnchors(top: view.topAnchor, padding: UIEdgeInsets(top: 6, left: 00, bottom: 0, right: 0))
        drawerIconView.centerAnchors(centerX: view.centerXAnchor)
        drawerIconView.dimensionAnchors(height: 3, width: 32)

        userSearchBar.edgeAnchors(top: drawerIconView.bottomAnchor,
                                  leading: view.leadingAnchor,
                                  trailing: view.trailingAnchor,
                                  padding: UIEdgeInsets(top: 6, left: 10, bottom: 0, right: -10))
        userSearchBar.dimensionAnchors(height: 30)

        tableView.edgeAnchors(top: userSearchBar.bottomAnchor,
                              leading: view.leadingAnchor,
                              bottom: view.bottomAnchor,
                              trailing: view.trailingAnchor,
                              padding: UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0))
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

    private func emptyTableViewMessage() {
        let viewRect = CGRect(origin: CGPoint(x: 0, y: 0),
                              size: CGSize(width: self.view.bounds.size.width,
                                           height: self.view.bounds.size.height))
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

    private func restoreTableView() {
        tableView.backgroundView = nil
        tableView.separatorStyle = .singleLine
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = viewModel.userCellModels?.count, count > 0 {
            restoreTableView()
        } else {
            emptyTableViewMessage()
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
//        guard tableView.panGestureRecognizer.isEnabled, let cell = tableView.cellForRow(at: indexPath) as? UserCell,
//            let email = cell.usernameLabel, let user = users?.first(where: { $0.email == email.text }) else { return }
//        cell.isSelected = false
//        delegate.setUserDetailCardVisible(withUser: user)
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
        self.searchText.onNext(searchText)
    }

}

protocol SearchTableViewControllerDelegate: class {
    func updateCoordinatesDuringPan(to translationPoint: CGPoint, withVelocity velocity: CGPoint)
    func updateCoordinatesAfterPan(to translationPoint: CGPoint, withVelocity velocity: CGPoint)
    func animateToExpanded()
    func setUserDetailCardVisible(withUser user: LocalUser)
    func updateDetailCard(withUser user: LocalUser)
}
