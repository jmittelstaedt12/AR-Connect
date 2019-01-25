//
//  JMMKMapView.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 1/24/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import MapKit

final class JMMKMapView: MKMapView {

    var compassButton: MKCompassButton!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setProperties()
        addCompass()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func setProperties() {
        mapType = .standard
        isZoomEnabled = true
        isScrollEnabled = true
        showsCompass = false
        translatesAutoresizingMaskIntoConstraints = false
    }

    private func addCompass() {
        compassButton = MKCompassButton(mapView: self)
        compassButton.compassVisibility = .visible
        compassButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(compassButton)
    }
}
