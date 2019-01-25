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

final class ARSessionViewController: UIViewController {

    var currentLocation: CLLocation!
    var tripCoordinates: [CLLocationCoordinate2D] = []
    var worldAlignment: ARWorldTrackingConfiguration.WorldAlignment!

    private var nodes: [JMNode] = []
    private var anchors: [ARAnchor] = []
    private var settingNorth = false

    var sceneView: ARSCNView! {
        didSet {
            sceneView.translatesAutoresizingMaskIntoConstraints = false
            sceneView.delegate = self
            sceneView.showsStatistics = true
            sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
        }
    }

    var configuration: ARWorldTrackingConfiguration! {
        didSet {
            configuration.worldAlignment = worldAlignment
            configuration.planeDetection = .horizontal
        }
    }

    let dismissButton: ARSessionButton = {
        let btn = ARSessionButton(type: .system)
        btn.setTitle("Dismiss", for: .normal)
        btn.addTarget(nil, action: #selector(dismissARSession), for: .touchUpInside)
        return btn
    }()

    var tapGestureRecognizer: UITapGestureRecognizer? {
        willSet {
            guard let gesture = newValue else { return }
            gesture.addTarget(self, action: #selector(didTap(sender:)))
            sceneView.isUserInteractionEnabled = true
            sceneView.addGestureRecognizer(gesture)
        }
    }

    var mapView: JMMKMapView?

    var finishedSettingNorthButton: ARSessionButton? {
        willSet {
            guard let btn = newValue else { return }
            btn.setTitle("Apply", for: .normal)
            btn.addTarget(self, action: #selector(didSetTrueNorth), for: .touchUpInside)
        }
    }

    var requestNorthCalibrationButton: ARSessionButton? {
        willSet {
            guard let btn = newValue else { return }
            btn.setTitle("Set North", for: .normal)
            btn.addTarget(self, action: #selector(setupViewForNorthCalibration), for: .touchUpInside)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView = ARSCNView()
        configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        addSubviews()
        setupSubviews()
        didReceiveTripSteps(tripCoordinates)
    }

    override func viewDidAppear(_ animated: Bool) {
        mapView?.compassButton.isHidden = false
    }

    private func addSubviews() {
        view.addSubview(sceneView)
        view.addSubview(dismissButton)
        if worldAlignment == .gravity { addSubviewsForTrueNorthCalibration() }
    }

    private func setupSubviews() {
        sceneView!.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor,
                               bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor)

        dismissButton.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor,
                                  padding: UIEdgeInsets(top: 12, left: 12, bottom: 0, right: 0))
        dismissButton.dimensionAnchors(height: 30, width: 60)

        if worldAlignment == .gravity {
            setupSubviewsForTrueNorthCalibration()
        } else {
            createNodesAndAnchors()
        }
    }

    private func addSubviewsForTrueNorthCalibration() {
        settingNorth = true
        let node = JMNode(geometry: SCNSphere(radius: 0.1))
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        node.position = SCNVector3(0, 0, -10)
        sceneView.scene.rootNode.addChildNode(node)
        tapGestureRecognizer = UITapGestureRecognizer()
        finishedSettingNorthButton = ARSessionButton(type: .system)
        view.addSubview(finishedSettingNorthButton!)
        mapView = JMMKMapView()
        view.addSubview(mapView!)
        mapView?.isUserInteractionEnabled = false
        let coordinateForMap = CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude+0.001, longitude: currentLocation.coordinate.longitude)
        LocationService.setMapProperties(for: mapView!, in: view, atCoordinate: coordinateForMap, withCoordinateSpan: 0.02)
    }

    private func setupSubviewsForTrueNorthCalibration() {
        finishedSettingNorthButton?.edgeAnchors(bottom: view.safeAreaLayoutGuide.bottomAnchor,
                                                padding: UIEdgeInsets(top: 0, left: 0, bottom: -32, right: 0))
        finishedSettingNorthButton?.centerAnchors(centerX: sceneView.centerXAnchor)
        finishedSettingNorthButton?.dimensionAnchors(height: 48, width: 80)

        mapView?.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: UIEdgeInsets(top: 12, left: 0, bottom: 0, right: -12))
        mapView?.dimensionAnchors(height: 150, width: 100)
        mapView?.compassButton.edgeAnchors(top: mapView?.topAnchor, padding: UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0))
        mapView?.compassButton.centerAnchors(centerX: mapView?.centerXAnchor)
    }

    @objc func didTap(sender: UITapGestureRecognizer) {
        if sender.location(in: sceneView).x < sceneView.bounds.width / 2 {
            rotateWorldOrigin(withAngle: -5.0.toRadians())
        } else {
            rotateWorldOrigin(withAngle: 5.0.toRadians())
        }
    }

    @objc private func didSetTrueNorth() {
        finishedSettingNorthButton?.removeFromSuperview()
        finishedSettingNorthButton = nil
        let childNodes = sceneView.scene.rootNode.childNodes
        for node in childNodes {
            node.removeFromParentNode()
        }
        if let tap = tapGestureRecognizer { view.removeGestureRecognizer(tap) }
        tapGestureRecognizer = nil
        mapView?.removeFromSuperview()
        mapView = nil

        requestNorthCalibrationButton = ARSessionButton(type: .system)
        view.addSubview(requestNorthCalibrationButton!)
        requestNorthCalibrationButton!.edgeAnchors(top: sceneView.topAnchor, trailing: sceneView.trailingAnchor, padding: UIEdgeInsets(top: 12, left: -12, bottom: 0, right: 0))
        requestNorthCalibrationButton!.dimensionAnchors(height: 30, width: 80)
        view.layoutSubviews()
        settingNorth = false
        createNodesAndAnchors()
    }

    @objc private func setupViewForNorthCalibration() {
        requestNorthCalibrationButton?.removeFromSuperview()
        requestNorthCalibrationButton = nil
        let childNodes = sceneView.scene.rootNode.childNodes
        for node in childNodes {
            node.removeFromParentNode()
            if let jmNode = node as? JMNode, let anchor = jmNode.anchor {
                sceneView.session.remove(anchor: anchor)
            }
        }
        addSubviewsForTrueNorthCalibration()
        setupSubviewsForTrueNorthCalibration()
    }

    private func createNodesAndAnchors() {
        guard !tripCoordinates.isEmpty, nodes.isEmpty, !settingNorth else { return }
        for coordinate in tripCoordinates {
            let transform = MatrixOperations.transformMatrix(for: matrix_identity_float4x4, originLocation: currentLocation, location: CLLocation(coordinate: coordinate))
            let node = JMNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0), location: coordinate)
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            node.position = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            node.anchor = ARAnchor(transform: transform)
            sceneView.session.add(anchor: node.anchor!)
            sceneView.scene.rootNode.addChildNode(node)
            nodes.append(node)
        }
    }

    private func updateNodesAndAnchors() {
        guard !nodes.isEmpty else { return }
        nodes = nodes.map { node -> JMNode in
            let newNode = JMNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0), location: node.coordinate)
            let transform = MatrixOperations.transformMatrix(for: matrix_identity_float4x4, originLocation: currentLocation, location: CLLocation(coordinate: node.coordinate))
            newNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            newNode.position = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            newNode.anchor = ARAnchor(transform: transform)
            sceneView.scene.rootNode.replaceChildNode(node, with: newNode)
            if let anchor = node.anchor { sceneView.session.remove(anchor: anchor) }
            sceneView.session.add(anchor: newNode.anchor!)
            return newNode
        }
    }

    private func rotateWorldOrigin(withAngle angle: Double) {
        let rotation = MatrixOperations.rotateAroundY(with: matrix_identity_float4x4, for: Float(angle))
        sceneView?.session.setWorldOrigin(relativeTransform: simd_mul(rotation, matrix_identity_float4x4))
    }

    @objc private func dismissARSession() {
        dismiss(animated: true, completion: nil)
    }

}

extension ARSessionViewController: LocationUpdateDelegate {

    func didReceiveLocationUpdate(to location: CLLocation) {
        currentLocation = location
        updateNodesAndAnchors()

    }

    func didReceiveTripSteps(_ steps: [CLLocationCoordinate2D]) {
        guard !steps.isEmpty, tripCoordinates.isEmpty else { return }
        var current = steps.first!
        tripCoordinates = steps.dropFirst().flatMap { step -> [CLLocationCoordinate2D] in
            let coordinates = LocationHelper.createIntermediaryCoordinates(from: current, to: step, withInterval: 5)
            current = step
            return coordinates
        }
        createNodesAndAnchors()
    }

}

extension ARSessionViewController: ARSCNViewDelegate {

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
