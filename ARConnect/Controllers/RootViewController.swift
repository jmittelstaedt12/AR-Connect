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
        let new = UINavigationController(rootViewController: LoginViewController(viewModel: LoginViewModel()))
        customizeNavigationBar(new.navigationBar)
        addChild(new)
        new.view.frame = view.bounds
        view.addSubview(new.view)
        new.didMove(toParent: self)
        current.willMove(toParent: nil)
        current.view.removeFromSuperview()
        current.removeFromParent()
        current = new
    }

    private func customizeNavigationBar(_ bar: UINavigationBar) {
        bar.barTintColor = ColorConstants.primaryColor
        bar.alpha = 0.9
        bar.tintColor = UIColor.white
        bar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    }

    // Display the testing view controlelr
    func switchToTesting() {
        let testingScreen = UINavigationController(rootViewController: TestingViewController())
        customizeNavigationBar(testingScreen.navigationBar)
        animateFadeTransition(to: testingScreen)
    }

    // If a user signs in, display the main map screen
    func switchToMainScreen() {
        //        let mainScreen = UINavigationController(rootViewController: TestingViewController())
        let mainScreen = UINavigationController(rootViewController: MainViewController(viewModel: MainViewModel()))
        customizeNavigationBar(mainScreen.navigationBar)
        animateFadeTransition(to: mainScreen)
    }

    // If the user signs out, switch to the login screen
    func switchToLogout() {
        let logoutScreen = UINavigationController(rootViewController: LoginViewController(viewModel: LoginViewModel()))
        customizeNavigationBar(logoutScreen.navigationBar)
        animateDismissTransition(to: logoutScreen)
    }

    // Animation for presenting main map screen
    private func animateFadeTransition(to new: UIViewController, completion: (() -> Void)? = nil) {
        current.willMove(toParent: nil)
        addChild(new)
        transition(from: current, to: new, duration: 0.3,
                   options: [.transitionCrossDissolve, .curveEaseOut],
                   animations: nil) { _ in
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
        transition(from: current, to: new, duration: 0.3,
                   options: [],
                   animations: {
                        new.view.frame = self.view.bounds
                   }, completion: { _ in
            self.current.removeFromParent()
            new.didMove(toParent: self)
            self.current = new
            completion?()
        })
    }
}
