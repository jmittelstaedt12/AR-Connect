//
//  MapViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 11/21/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    let locationModel = LocationModel()
    
    let map : MKMapView = {
        let map = MKMapView()
        map.mapType = .standard
        map.isZoomEnabled = true
        map.isScrollEnabled = true
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view = map
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
