//
//  MainViewController+UICollectionViewDelegate.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/3/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

extension MainViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let collapsibleView = collectionView as! CollapsibleCollectionView
        if collapsibleView.collapsed {
            return 1
        } else {
            return 4
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collapsibleView = collectionView as! CollapsibleCollectionView
        let cell = collapsibleView.dequeueReusableCell(withReuseIdentifier: "buttonCell", for: indexPath) as! ButtonCollectionViewCell
        cell.backgroundColor = .white
        cell.button = collapsibleView.buttons[indexPath.row]
        cell.configure()
        return cell
    }
}
