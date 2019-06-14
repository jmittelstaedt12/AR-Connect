//
//  UserTableViewCell.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 1/9/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import RxSwift

class UserCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var isOnlineImageView: UIImageView!

    let disposeBag = DisposeBag()

    var userCellModel: UserCellModel! {
        didSet {
            nameLabel.text = userCellModel.name
            usernameLabel.text = userCellModel.username
            profileImageView.image = UIImage(named: "person-placeholder")

            userCellModel.profileImageData
                .subscribe(onNext: { [weak self] data in
                    self?.profileImageView.image = UIImage(data: data)
                })
                .disposed(by: disposeBag)

            userCellModel.isOnline
                .subscribe(onNext: { [weak self] online in
                    self?.isOnlineImageView.backgroundColor = online ? UIColor.green : UIColor.gray
                })
                .disposed(by: disposeBag)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    private func setupUI() {
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        isOnlineImageView.backgroundColor = .lightGray
        isOnlineImageView.layer.cornerRadius = isOnlineImageView.frame.width / 2
    }
}
