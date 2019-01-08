//
//  JMNavigationBar.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 12/19/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

class JMNavigationBar: UINavigationBar {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupNavigationBar()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupNavigationBar()
    }
    
    private func setupNavigationBar() {
        isTranslucent = true
        barTintColor = UIColor.gray
        alpha = 0.9
        tintColor = UIColor.white
        titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    }
}
