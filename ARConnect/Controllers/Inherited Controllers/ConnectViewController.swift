//
//  ConnectRequestViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 11/15/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import RxSwift
import MapKit

class ConnectViewController: UIViewController {

    let bag = DisposeBag()
    var user: LocalUser! {
        willSet {
            guard let user = newValue else { return }
            requestingUserNameLabel.text = user.name
            requestingUserImageView.image = user.profileImage ?? UIImage(named: "person-placeholder")
        }
    }

    var meetupLocation: CLLocationCoordinate2D!

    let requestingUserImageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .lightGray
        view.layer.cornerRadius = view.frame.width / 2
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

    lazy var meetupLocationMapView: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.isUserInteractionEnabled = false
        let annotation = MKPointAnnotation()
        annotation.coordinate = meetupLocation
        map.addAnnotation(annotation)
        LocationService.setMapProperties(for: map, in: self.view, atCoordinate: meetupLocation, withCoordinateSpan: 0.01)
        return map
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(requestingUserImageView)
        view.addSubview(requestingUserNameLabel)
        view.addSubview(cancelButton)
        view.addSubview(meetupLocationMapView)
    }

    func setViewLayouts() { fatalError("this method must be overridden") }

    @objc func handleResponse(sender: UIButton) { fatalError("this method must be overridden") }
}
