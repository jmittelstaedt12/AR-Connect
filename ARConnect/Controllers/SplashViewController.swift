//
//  SplashViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/11/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase

final class SplashViewController: UIViewController {

    private let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        view.addSubview(activityIndicator)
        activityIndicator.frame = view.bounds
        activityIndicator.backgroundColor = UIColor(white: 0, alpha: 0.4)
        makeServiceCall()
    }
    private func makeServiceCall() {
        activityIndicator.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
            self.activityIndicator.stopAnimating()
            if Auth.auth().currentUser?.uid == nil {
                AppDelegate.shared.rootViewController.switchToLogout()
            } else {
//                AppDelegate.shared.rootViewController.switchToTesting()
                AppDelegate.shared.rootViewController.switchToMainScreen()
            }
        }
    }

}
