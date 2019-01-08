//
//  JMButton.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 12/13/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

class JMButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupButton()
    }
    
    private func setupButton() {
//        setTitleColor(UIColor.black, for: .normal)
        titleLabel?.textColor                           = .black
        backgroundColor                                 = .white
        layer.cornerRadius                              = 5
        translatesAutoresizingMaskIntoConstraints       = false
        isHidden                                        = false
    }
    
}
