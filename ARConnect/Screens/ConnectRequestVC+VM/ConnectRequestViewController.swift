//
//  ConnectRequestViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 11/15/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase
import MapKit
import RxSwift

final class ConnectRequestViewController: ConnectViewController, ControllerProtocol {

    // MARK: Properties

    typealias ViewModelType = ConnectRequestViewModel
    var viewModel: ViewModelType!
    let disposeBag = DisposeBag()

    func configure(with viewModel: ViewModelType) {
        self.currentLocation = viewModel.currentLocation
        self.meetupLocation = viewModel.meetupLocation
        requestingUserNameLabel.text = viewModel.nameString
        requestingUserImageView.image = (viewModel.profileImageData != nil) ?
            UIImage(data: viewModel.profileImageData!) : UIImage(named: "person-placeholder")

        viewModel.output.processedResponseObservable
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .success:
                    self?.dismiss(animated: true, completion: nil)
                case .failure(let error):
                    self?.createAndDisplayAlert(withTitle: error.title, body: error.errorDescription)
                }
            })
            .disposed(by: disposeBag)

        viewModel.output.callDroppedObservable
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.createAndDisplayAlert(withTitle: "Call Dropped", body: "Ending call")
                self.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }

    var acceptButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Confirm", for: .normal)
        btn.addTarget(self, action: #selector(handleResponse(sender:)), for: .touchUpInside)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(acceptButton)
        setViewLayouts()
//        setObservers()
    }

    override func setViewLayouts() {
        // Set profile image view constraints
        requestingUserImageView.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor,
                                            leading: view.safeAreaLayoutGuide.leadingAnchor,
                                            padding: UIEdgeInsets(top: 30, left: 32, bottom: 0, right: 0))
        requestingUserImageView.dimensionAnchors(height: 80, width: 80)

        // Set name label constraints
        requestingUserNameLabel.edgeAnchors(leading: requestingUserImageView.trailingAnchor,
                                            bottom: requestingUserImageView.bottomAnchor,
                                            padding: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0))
        requestingUserNameLabel.dimensionAnchors(height: 20)

        // Set map view constraints
        meetupLocationMapView.edgeAnchors(top: requestingUserImageView.bottomAnchor,
                                          padding: UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0))
        meetupLocationMapView.centerAnchors(centerX: view.safeAreaLayoutGuide.centerXAnchor)
        meetupLocationMapView.dimensionAnchors(width: view.safeAreaLayoutGuide.widthAnchor, widthConstant: -16)

        // set accept button constraints
        acceptButton.edgeAnchors(top: meetupLocationMapView.bottomAnchor,
                                 padding: UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0))
        acceptButton.centerAnchors(centerX: view.safeAreaLayoutGuide.centerXAnchor)

        // set cancel button constriants
        cancelButton.edgeAnchors(top: acceptButton.bottomAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor,
                                 padding: UIEdgeInsets(top: 16, left: 0, bottom: -16, right: 0))
        cancelButton.centerAnchors(centerX: view.safeAreaLayoutGuide.centerXAnchor)
    }

    override func handleResponse(sender: UIButton) {
        viewModel.handleResponse(senderTitle: sender.title(for: .normal)!)
    }
}
