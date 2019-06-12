//
//  CellDetailViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 11/8/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase
import RxSwift

protocol CardDetailDelegate: class {
    func willSetMeetupLocation(withUser user: LocalUser)
    func removeFromHierarchy()
}

final class CardDetailViewController: UIViewController {

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var connectButton: UIButton!

    weak var delegate: CardDetailDelegate?

    let currentUser = Auth.auth().currentUser
    let bag = DisposeBag()

    var userForCell: LocalUser! {
        didSet {
            userImageView.image = userForCell?.profileImage ?? UIImage(named: "person-placeholder")
            userImageView.contentMode = .scaleAspectFill
            userImageView.clipsToBounds = true
            nameLabel.text = userForCell?.name
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupUIElements()
    }

    private func setupView() {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 5
        view.layer.borderColor = UIColor.blue.cgColor
        view.layer.borderWidth = 1
    }

    private func setupUIElements() {
        cancelButton.setTitle("Cancel", for: .normal)
        messageButton.setTitle("Message", for: .normal)
        connectButton.setTitle("Connect", for: .normal)
    }

    @IBAction func onCancel(_ sender: UIButton) {
        delegate?.removeFromHierarchy()
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }

    @IBAction func connectToUser(_ sender: UIButton) {
        delegate?.willSetMeetupLocation(withUser: userForCell)
        delegate?.removeFromHierarchy()
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }

    @IBAction func messageUser(_ sender: UIButton) {
        let messageVC = MessageViewController()
        self.navigationController?.pushViewController(messageVC, animated: true)
    }

    deinit {
        print("deinit card detail")
    }
}
