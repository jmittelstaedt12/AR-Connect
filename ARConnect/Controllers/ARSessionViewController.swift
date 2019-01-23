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

    var sceneView: ARSCNView? {
        willSet {
            newValue?.translatesAutoresizingMaskIntoConstraints = false
            newValue?.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
        }
    }

    let dismissButton: UIButton = {
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
        sceneView = ARSCNView()
        sceneView!.delegate = self
        configureARSession()
        view.addSubview(sceneView!)
        view.addSubview(dismissButton)
        setupSceneView()
        setupDismissButton()
        didReceiveTripSteps(tripCoordinates)
        createNodes()
    }

    override func viewWillDisappear(_ animated: Bool) {
        //        sceneView?.removeFromSuperview()
        //        sceneView = nil
    }

    private func configureARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = ARWorldTrackingConfiguration.WorldAlignment.gravityAndHeading
        sceneView!.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    /// Set auto layout anchors for scene view
    private func setupSceneView() {
        sceneView!.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor)
    }

    /// Set auto layout anchors for dismiss AR Session button
    private func setupDismissButton() {
        dismissButton.edgeAnchors(top: sceneView!.topAnchor, leading: sceneView!.leadingAnchor, padding: UIEdgeInsets(top: 12, left: 12, bottom: 0, right: 0))
        dismissButton.dimensionAnchors(height: 30, width: 60)
    }

    //    /// Place node in current AR Session at target location
    //    private func addTargetNode() {
    //        let node = SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0))
    //        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
    //        let arCoordinates = LocationHelper.getARCoordinates(from: currentLocation, to: targetLocation)
    //        node.position = SCNVector3(arCoordinates.latitude, 0, -arCoordinates.longitude)
    //        sceneView.scene.rootNode.addChildNode(node)
    //    }

    private func createNodes() {
        if tripCoordinates.count < 10 { return }
        for index in 0..<tripCoordinates.count {
            if index > 1 {
                print(CLLocation(coordinate: tripCoordinates[index]).distance(from: CLLocation(coordinate: tripCoordinates[index - 1])))
            }
            let node = SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0))
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            let transform = MatrixOperations.transformMatrix(for: matrix_identity_float4x4, originLocation: currentLocation, location: CLLocation(coordinate: tripCoordinates[index]))
            node.position = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            let anchor = ARAnchor(transform: transform)
            sceneView!.session.add(anchor: anchor)
            sceneView!.scene.rootNode.addChildNode(node)
        }
    }

    func didReceiveLocationUpdate(to location: CLLocation) {
        currentLocation = location
    }

    func didReceiveTripSteps(_ steps: [CLLocationCoordinate2D]) {
        guard !steps.isEmpty else { return }
        var current = steps.first!
        print(steps.count)
        print(steps)
        tripCoordinates = steps.dropFirst().flatMap { step -> [CLLocationCoordinate2D] in
            let coordinates = LocationHelper.createIntermediaryCoordinates(from: current, to: step, withInterval: 5)
            current = step
            return coordinates
        }
        print(tripCoordinates)
        createNodes()
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
