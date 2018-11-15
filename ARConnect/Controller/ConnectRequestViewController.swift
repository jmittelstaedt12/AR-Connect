//
//  ConnectRequestViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 11/15/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

class ConnectRequestViewController: UIViewController {

    let requestingUserImageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .lightGray
        return view
    }()
    
    let acceptButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Confirm", for: .normal)
        btn.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)
        return btn
    }()
    
    let denyButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Deny", for: .normal)
        btn.addTarget(self, action: #selector(onDeny), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(requestingUserImageView)
        view.addSubview(acceptButton)
        view.addSubview(denyButton)
        setViewLayouts()
    }
    
    private func setViewLayouts() {
        requestingUserImageView.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: UIEdgeInsets(top: 60, left: 32, bottom: 0, right: -32))
        requestingUserImageView.centerAnchors(centerX: view.safeAreaLayoutGuide.centerXAnchor)
        requestingUserImageView.dimensionAnchors(height: view.frame.width - 64)
        acceptButton.edgeAnchors(top: requestingUserImageView.bottomAnchor, padding: UIEdgeInsets(top: 32, left: 0, bottom: 0, right: 0))
        acceptButton.centerAnchors(centerX: view.safeAreaLayoutGuide.centerXAnchor)
        denyButton.edgeAnchors(top: acceptButton.bottomAnchor, padding: UIEdgeInsets(top: 32, left: 0, bottom: 0, right: 0))
        denyButton.centerAnchors(centerX: view.safeAreaLayoutGuide.centerXAnchor)
    }
    
    @objc private func onConfirm() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func onDeny() {
        self.dismiss(animated: true, completion: nil)
    }

}
