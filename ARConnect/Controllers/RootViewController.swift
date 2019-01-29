//
//  RootViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/11/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import Firebase

final class RootViewController: UIViewController {

    private var current: UIViewController

    init() {
        self.current = SplashViewController()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        self.current = SplashViewController()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(current)
        current.view.frame = view.bounds
        view.addSubview(current.view)
        current.didMove(toParent: self)
    }

    // Displays the login screen
    // If there was no user signed in on last app close, this will display the login screen
    func showLoginScreen() {
        let new = UINavigationController(rootViewController: LoginViewController())
        addChild(new)
        new.view.frame = view.bounds
        view.addSubview(new.view)
        new.didMove(toParent: self)
        current.willMove(toParent: nil)
        current.view.removeFromSuperview()
        current.removeFromParent()
        current = new
    }

    // Display the testing view controlelr
    func switchToTesting() {
        let testingScreen = UINavigationController(rootViewController: TestingViewController())
        animateFadeTransition(to: testingScreen)
    }

    // If a user signs in, display the main map screen
    func switchToMainScreen() {
        //        let mainScreen = UINavigationController(rootViewController: TestingViewController())
        let mainScreen = UINavigationController(rootViewController: MainViewController())
        animateFadeTransition(to: mainScreen)
    }

    // If the user signs out, switch to the login screen
    func switchToLogout() {
        let logoutScreen = UINavigationController(rootViewController: LoginViewController())
        animateDismissTransition(to: logoutScreen)
    }

    // Animation for presenting main map screen
    private func animateFadeTransition(to new: UIViewController, completion: (() -> Void)? = nil) {
        current.willMove(toParent: nil)
        addChild(new)
        transition(from: current, to: new, duration: 0.3, options: [.transitionCrossDissolve, .curveEaseOut], animations: nil) { _ in
            self.current.removeFromParent()
            new.didMove(toParent: self)
            self.current = new
            completion?()
        }
    }

    // Animation for dismissing
    private func animateDismissTransition(to new: UIViewController, completion: (() -> Void)? = nil) {
        current.willMove(toParent: nil)
        addChild(new)
        transition(from: current, to: new, duration: 0.3, options: [], animations: {
                new.view.frame = self.view.bounds
            }, completion: { _ in
            self.current.removeFromParent()
            new.didMove(toParent: self)
            self.current = new
            completion?()
        })
    }
}
