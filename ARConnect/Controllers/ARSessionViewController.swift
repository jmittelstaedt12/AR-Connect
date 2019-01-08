//
//  ARSessionViewController.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 10/9/18.
//  Copyright © 2018 Jacob Mittelstaedt. All rights reserved.
//

import UIKit
import ARKit
import MapKit

final class ARSessionViewController: UIViewController, ARSCNViewDelegate, LocationUpdateDelegate {
    
    var startLocation: CLLocation!
    var currentLocation: CLLocation!
    var targetLocation: CLLocation!
    var tripCoordinates: [CLLocationCoordinate2D] = []
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
        
        view.addSubview(sceneView)
        view.addSubview(dismissButton)
        setupSceneView()
        setupDismissButton()
        
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
        
//        addTargetNode()
        createNodes()
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
    
    /// Set auto layout anchors for scene view
    private func setupSceneView() {
        sceneView.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor)
    }
    
    /// Set auto layout anchors for dismiss AR Session button
    private func setupDismissButton() {
        dismissButton.edgeAnchors(top: sceneView.topAnchor, leading: sceneView.leadingAnchor, padding: UIEdgeInsets(top: 12, left: 12, bottom: 0, right: 0))
        dismissButton.dimensionAnchors(height: 30, width: 60)
    }
    
    /// Place node in current AR Session at target location
    private func addTargetNode() {
        let node = SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0))
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        let arCoordinates = LocationHelper.getARCoordinates(from: currentLocation, to: targetLocation)
        node.position = SCNVector3(arCoordinates.0, 0, -arCoordinates.1)
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    
    private func createNodes() {
        if tripCoordinates.count < 10 { return }
        for i in 0..<10 {
            let node = SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0))
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            let arCoordinates = LocationHelper.getARCoordinates(from: currentLocation, to: CLLocation(coordinate: tripCoordinates[i]))
            print(arCoordinates.0, arCoordinates.1)
            node.position = SCNVector3(arCoordinates.0, 0, arCoordinates.1)
            #warning("Update this function to display nodes")
//            sceneView.scene.rootNode.addChildNode(node)
        }
//        for nodeLocation in locations {
//            let node = SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0))
//            node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
//            let arCoordinates = LocationModel.getARCoordinates(from: currentLocation, to: nodeLocation)
//            node.position = SCNVector3(arCoordinates.0, 0, arCoordinates.1)
//            sceneView.scene.rootNode.addChildNode(node)
//        }
    }
    
    func didReceiveLocationUpdate(to location: CLLocation) {
        currentLocation = location
    }
    
    func didReceiveTripSteps(_ steps: [CLLocationCoordinate2D]) {
        guard !steps.isEmpty else { return }
        var current = steps.first!
        var stepsWithIntermediaries = steps
        for (index,step) in steps.enumerated() {
            let stepPoints = LocationHelper.createIntermediaryCoordinates(from: current, to: step, withInterval: 5)
            stepsWithIntermediaries.insert(contentsOf: stepPoints, at: index)
        }        
        tripCoordinates = stepsWithIntermediaries
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
