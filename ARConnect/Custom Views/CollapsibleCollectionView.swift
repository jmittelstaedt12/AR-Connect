//
//  CollapsibleCollectionView.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/3/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

final class CollapsibleCollectionView: UICollectionView, UICollectionViewDataSource {

    var collapsed: Bool!

    enum GrowDirection {
        case fromTop, fromBottom
    }

    var growDirection: GrowDirection!

    let expandButton: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("^", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.addTarget(self, action: #selector(expandCollection), for: .touchUpInside)
        return btn
    }()

    var buttons: [UIButton]!

    init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout, collapsed: Bool, buttons: [UIButton], growDirection: GrowDirection = .fromTop) {
        super.init(frame: frame, collectionViewLayout: layout)

        // Initialize stored properties
        self.collapsed = collapsed
        self.buttons = [expandButton] + buttons
        self.growDirection = growDirection
        register(ButtonCollectionViewCell.self, forCellWithReuseIdentifier: "buttonCell")

        // Set attributes
        if growDirection == .fromBottom {
            transform = CGAffineTransform(scaleX: 1, y: -1)
        }
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        dataSource = self
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc private func expandCollection() {
        self.collapsed.toggle()
        let cell = cellForItem(at: IndexPath(row: 0, section: 0)) as! ButtonCollectionViewCell
        let paths = Array(self.buttons.enumerated().map { IndexPath(row: $0.0, section: 0) }[1...])
        self.performBatchUpdates({
            cell.button!.rotate(collapsed ? 0.0 : .pi)
            if self.collapsed {
                self.deleteItems(at: paths)
            } else {
                self.insertItems(at: paths)
            }
        })
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collapsed ? 1 : buttons.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = dequeueReusableCell(withReuseIdentifier: "buttonCell", for: indexPath) as! ButtonCollectionViewCell
        cell.backgroundColor = .white
        cell.button = buttons[indexPath.row]
        if growDirection == .fromBottom {
            cell.button!.transform = CGAffineTransform(scaleX: 1, y: -1)
        }
        cell.configure()
        return cell
    }

}
