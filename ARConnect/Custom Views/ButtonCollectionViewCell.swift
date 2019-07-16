//
//  ButtonCollectionViewCell.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/5/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

final class ButtonCollectionViewCell: UICollectionViewCell {

    var button: UIButton?

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 25
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func configure() {
        guard let button = button else { return }
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        button.edgeAnchors(top: safeAreaLayoutGuide.topAnchor, leading: safeAreaLayoutGuide.leadingAnchor, bottom: safeAreaLayoutGuide.bottomAnchor,
                           trailing: safeAreaLayoutGuide.trailingAnchor, padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
    }

}
