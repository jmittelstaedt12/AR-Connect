//
//  InitialViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 12/19/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit

final class InitialViewController: UIViewController {

    let logo: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    let loginButton: JMButton = {
        let btn = JMButton()
        btn.setTitle("Log In", for: .normal)
        return btn
    }()

    let signUpButton: JMButton = {
        let btn = JMButton()
        btn.setTitle("Sign Up", for: .normal)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorConstants.primaryColor
        addSubviews()
        setSubviewLayouts()
        // Do any additional setup after loading the view.
    }

    private func addSubviews() {
        view.addSubview(logo)
        view.addSubview(loginButton)
        view.addSubview(signUpButton)
    }

    private func setSubviewLayouts() {
        logo.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, padding: UIEdgeInsets(top: 48, left: 0, bottom: 0, right: 0))
        logo.centerAnchors(centerX: view.centerXAnchor)
        logo.dimensionAnchors(height: 60, width: 60)

        loginButton.edgeAnchors(top: logo.bottomAnchor, padding: UIEdgeInsets(top: 48, left: 0, bottom: 0, right: 0))
        loginButton.centerAnchors(centerX: view.centerXAnchor)
        loginButton.dimensionAnchors(height: 20, width: 40)

        signUpButton.edgeAnchors(top: loginButton.bottomAnchor, padding: UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0))
        signUpButton.centerAnchors(centerX: view.centerXAnchor)
        signUpButton.dimensionAnchors(height: 20, width: 40)
    }

}
