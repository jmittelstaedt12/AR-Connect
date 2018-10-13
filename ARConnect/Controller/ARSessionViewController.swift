//
//  ARSessionViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/9/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import ARKit
import MapKit

class ARSessionViewController: UIViewController, ARSCNViewDelegate {

    var currentLocation: CLLocation!
    var targetLocation: CLLocation!
    var currentCoordinates: CLLocationCoordinate2D!
    var targetCoordinates: CLLocationCoordinate2D!
    
    let sceneView : ARSCNView = {
        let view = ARSCNView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let dismissButton : UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Dismiss", for: .normal)
        btn.setTitleColor(UIColor.black, for: .normal)
        btn.backgroundColor = UIColor.white
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(nil, action: #selector(dismissARSession), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentCoordinates = currentLocation.coordinate
        targetCoordinates = targetLocation.coordinate
        
        view.addSubview(sceneView)
        view.addSubview(dismissButton)
        setupSceneView()
        setupDismissButton()
        
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
        
        addTargetNode()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = ARWorldTrackingConfiguration.WorldAlignment.gravityAndHeading
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // Set auto layout anchors for scene view
    private func setupSceneView() {
        sceneView.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor)
    }
    
    // Set auto layout anchors for dismiss AR Session button
    private func setupDismissButton() {
        dismissButton.edgeAnchors(top: sceneView.topAnchor, leading: sceneView.leadingAnchor, padding: UIEdgeInsets(top: 12, left: 12, bottom: 0, right: 0))
        dismissButton.dimensionAnchors(height: 30, width: 60)
    }
    
    
    private func calculateBearing() -> Double {
        #warning("move into location model")
        let a = sin(targetCoordinates.longitude.toRadians() - currentCoordinates.longitude.toRadians()) * cos(targetCoordinates.latitude.toRadians())
        let b = cos(currentCoordinates.latitude.toRadians()) * sin(targetCoordinates.latitude.toRadians()) - sin(currentCoordinates.latitude.toRadians()) * cos(targetCoordinates.latitude.toRadians()) * cos(currentCoordinates.longitude.toRadians() - targetCoordinates.longitude.toRadians())
        return atan2(a, b)
    }
    
    private func addTargetNode() {
        let node = SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0))
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        let d = currentLocation.distance(from: targetLocation)
        let b = calculateBearing()
        let x = d*cos(b)
        let y = d*sin(b)
        node.position = SCNVector3(x, 0, -y)
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    @objc private func dismissARSession() {
        dismiss(animated: true, completion: nil)
    }
    // MARK: - ARSCNViewDelegate
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }

}

extension Double {
    func toRadians() -> Double {
        return self * .pi / 180.0
    }
    
    func toDegrees() -> Double {
        return self * 180.0 / .pi
    }
}
