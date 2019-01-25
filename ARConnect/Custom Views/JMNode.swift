//
//  JMNode.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 1/23/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import ARKit
import MapKit

class JMNode: SCNNode {

    var coordinate: CLLocationCoordinate2D!
    var anchor: ARAnchor?

    init(geometry: SCNGeometry? = nil, location: CLLocationCoordinate2D? = nil) {
        super.init()
        self.geometry = geometry
        self.coordinate = location
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
