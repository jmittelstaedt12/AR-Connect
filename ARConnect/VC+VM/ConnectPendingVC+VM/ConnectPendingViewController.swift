//
//  InheritingTestViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 1/8/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase
import RxSwift

final class ConnectPendingViewController: ConnectViewController, ControllerProtocol {

    // MARK: Properties

    typealias ViewModelType = ConnectPendingViewModel

    var viewModel: ViewModelType!

    let disposeBag = DisposeBag()

    func configure(with viewModel: ViewModelType) {
        self.currentLocation = viewModel.currentLocation
        self.meetupLocation = viewModel.meetupLocation
        requestingUserNameLabel.text = viewModel.nameString
        requestingUserImageView.image = (viewModel.profileImageData != nil) ? UIImage(data: viewModel.profileImageData!) : UIImage(named: "person-placeholder")
        
        viewModel.output.wentOfflineObservable
            .subscribe(onNext: { [weak self] error in
                guard let self = self else { return }
                self.createAndDisplayAlert(withTitle: error.title, body: error.errorDescription)
                self.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)

        viewModel.output.callDroppedObservable
            .subscribe(onNext: { [weak self] error in
                guard let self = self else { return }
                self.createAndDisplayAlert(withTitle: error.title, body: error.errorDescription)
                self.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)

        viewModel.output.receivedResponseObservable
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        cancelButton.setTitle("Cancel", for: .normal)
        setViewLayouts()
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
        meetupLocationMapView.dimensionAnchors(height: 400)

        // set cancel button constriants
        cancelButton.edgeAnchors(top: meetupLocationMapView.bottomAnchor,
                                 bottom: view.bottomAnchor,
                                 padding: UIEdgeInsets(top: 16, left: 0, bottom: -16, right: 0))
        cancelButton.centerAnchors(centerX: view.safeAreaLayoutGuide.centerXAnchor)
    }

//    private func setTimer() {
//        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
//            FirebaseClient.usersRef.child(Auth.auth().currentUser!.uid).updateChildValues(["pendingRequest": false])
//            guard let self = self else { return }
//            self.createAndDisplayAlert(withTitle: "Call Timed Out", body: "\(self.user.name ?? "User") did not respond")
//            self.dismiss(animated: true, completion: nil)
//        }
//    }

    override func handleResponse(sender: UIButton) {
        if sender.title(for: .normal) == "Cancel" {
            viewModel.didCancel()
            dismiss(animated: true, completion: nil)
        }
    }

}
