//
//  ConnectRequestViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 11/15/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import RxSwift

class ConnectViewController: UIViewController {
    
    let bag = DisposeBag()
    var user: LocalUser! {
        willSet {
            if let name = newValue?.name {
                requestingUserNameLabel.text = name
            }
        }
    }
    
    let requestingUserImageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .lightGray
        return view
    }()
    
    let requestingUserNameLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .black
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    let cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Deny", for: .normal)
        btn.addTarget(self, action: #selector(handleResponse(sender:)), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(requestingUserImageView)
        view.addSubview(requestingUserNameLabel)
        view.addSubview(cancelButton)
    }
    
    func setViewLayouts() { fatalError("this method must be overridden") }
    
    @objc func handleResponse(sender: UIButton) { fatalError("this method must be overridden") }
}
