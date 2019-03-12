//
//  UserTableViewCell.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 1/9/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var isOnlineImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        // Initialization code
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
