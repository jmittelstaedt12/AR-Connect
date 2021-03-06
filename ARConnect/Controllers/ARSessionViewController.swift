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

    var startLocation: CLLocation!
    var tripCoordinates: [CLLocationCoordinate2D]!
    var tripLocations: [CLLocation]!
    var localCoordinates: [CLLocationCoordinate2D]?
    var currentLocation: CLLocation! {
        didSet {
            localCoordinates = Array((tripLocations
                .sorted { $0.distance(from: currentLocation) < $1.distance(from: currentLocation) }[0...9])
                .map { $0.coordinate })
        }
    }

//    var updatedLocations: [CLLocation] = [] {
//        didSet {
//            var locations = updatedLocations.sorted(by: { (first, second) -> Bool in
//                if first.horizontalAccuracy == second.horizontalAccuracy {
//                    return first.timestamp > second.timestamp
//                }
//                return first.horizontalAccuracy < second.horizontalAccuracy
//            })
//            print(locations.map{ $0.horizontalAccuracy })
//            currentLocation = locations.first
//        }
//    }

    var distanceTraveled: CLLocationDistance?

    var worldAlignment: ARWorldTrackingConfiguration.WorldAlignment!
//    var delegate: ARSessionViewControllerDelegate?

    private var nodes: [JMNode] = []
    private var settingNorth = false
    private var scheduledTimer: Timer?

    private var sceneView: ARSCNView! {
        didSet {
            sceneView.translatesAutoresizingMaskIntoConstraints = false
            sceneView.delegate = self
            sceneView.session.delegate = self
            sceneView.showsStatistics = true
            sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
        }
    }

    private var configuration: ARWorldTrackingConfiguration! {
        didSet {
            configuration.worldAlignment = worldAlignment
            configuration.planeDetection = .horizontal
            configuration.isLightEstimationEnabled = true
        }
    }

    private let dismissButton: ARSessionButton = {
        let btn = ARSessionButton(type: .system)
        btn.setTitle("Dismiss", for: .normal)
        btn.addTarget(self, action: #selector(dismissARSession), for: .touchUpInside)
        btn.layer.cornerRadius = 30
        btn.dimensionAnchors(height: 60, width: 60)
        return btn
    }()

    private var tapGestureRecognizer: UITapGestureRecognizer? {
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

    init(startLocation: CLLocation, tripLocations: [CLLocation], worldAlignment: ARWorldTrackingConfiguration.WorldAlignment) {
        super.init(nibName: nil, bundle: nil)
        self.tripLocations = tripLocations
        self.worldAlignment = worldAlignment
        self.startLocation = startLocation
        currentLocation = startLocation
        tripCoordinates = tripLocations.map { $0.coordinate }
        localCoordinates = Array((tripLocations
            .sorted { $0.distance(from: currentLocation!) < $1.distance(from: currentLocation!) }[0...9])
            .map { $0.coordinate })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView = ARSCNView()
        configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        addSubviews()
        setupSubviews()
        setTimerForReconfigure()
//        didReceiveTripSteps(tripCoordinates)
    }

    override func viewDidAppear(_ animated: Bool) {
        mapView?.compassButton.isHidden = false
    }

    private func addSubviews() {
        view.addSubview(sceneView)
        view.addSubview(dismissButton)

        /// If the heading accuracy is too low, setup view for setting true north manually
        if worldAlignment == .gravity {
            addSubviewsForTrueNorthCalibration()
        }
    }

    private func setupSubviews() {
        sceneView!.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor,
                               bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor)

        dismissButton.edgeAnchors(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor,
                                  padding: UIEdgeInsets(top: 12, left: 12, bottom: 0, right: 0))

        if worldAlignment == .gravity {
            settingNorth = true
            setupSubviewsForTrueNorthCalibration()
        } else {
            createNodesAndAnchors()
        }
    }

    /// Add all necessary subviews to allow for true north calibration
    private func addSubviewsForTrueNorthCalibration() {
        let node = JMNode(geometry: SCNSphere(radius: 0.1))
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        node.position = SCNVector3(0, 0, -10)
        sceneView.scene.rootNode.addChildNode(node)
        tapGestureRecognizer = UITapGestureRecognizer()
        view.addGestureRecognizer(tapGestureRecognizer!)
        finishedSettingNorthButton = ARSessionButton(type: .system)
        view.addSubview(finishedSettingNorthButton!)
        mapView = JMMKMapView()
        view.addSubview(mapView!)
        mapView?.isUserInteractionEnabled = false
        let locationCoordinate = (currentLocation ?? startLocation)!
        let coordinateForMap = CLLocationCoordinate2D(latitude: locationCoordinate.coordinate.latitude+0.001, longitude: locationCoordinate.coordinate.longitude)
        LocationService.setMapProperties(for: mapView!, in: view, atCoordinate: coordinateForMap, withCoordinateSpan: 0.01)
    }

    private func setupSubviewsForTrueNorthCalibration() {
        finishedSettingNorthButton?.edgeAnchors(bottom: mapView?.topAnchor,
                                                padding: UIEdgeInsets(top: 0, left: 0, bottom: -16, right: 0))
        finishedSettingNorthButton?.centerAnchors(centerX: sceneView.centerXAnchor)
        finishedSettingNorthButton?.dimensionAnchors(height: 48, width: 80)

        mapView?.edgeAnchors(bottom: view.safeAreaLayoutGuide.bottomAnchor, padding: UIEdgeInsets(top: 0, left: 0, bottom: -12, right: 0))
        mapView?.centerAnchors(centerX: view.safeAreaLayoutGuide.centerXAnchor)
        mapView?.dimensionAnchors(height: 150, width: 500)
        mapView?.compassButton.edgeAnchors(top: mapView?.topAnchor, padding: UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0))
        mapView?.compassButton.centerAnchors(centerX: mapView?.centerXAnchor)
    }

    /// Respond to taps during calibration. Will change north direction by +=5 degrees depending on
    /// which side of the screen was tapped
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
        if let tap = tapGestureRecognizer {
            view.removeGestureRecognizer(tap)
        }
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
        settingNorth = true     // Prevent nodes from being created while calibrating
        requestNorthCalibrationButton?.removeFromSuperview()
        requestNorthCalibrationButton = nil
        let childNodes = sceneView.scene.rootNode.childNodes
        for node in childNodes {
            node.removeFromParentNode()
        }
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        addSubviewsForTrueNorthCalibration()
        setupSubviewsForTrueNorthCalibration()
    }

    private func createNodesAndAnchors() {
        guard let coordinates = localCoordinates, !coordinates.isEmpty, !settingNorth else { return }
        nodes = []
        let childNodes = sceneView.scene.rootNode.childNodes
        for node in childNodes {
            node.removeFromParentNode()
        }
        for coordinate in coordinates {
            let transform = MatrixOperations.transformMatrix(for: matrix_identity_float4x4, originLocation: startLocation, location: CLLocation(coordinate: coordinate))
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
        guard !nodes.isEmpty, !settingNorth else { return }
        nodes = nodes.map { node -> JMNode in
            let newNode = JMNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0), location: node.coordinate)
            let transform = MatrixOperations.transformMatrix(for: matrix_identity_float4x4, originLocation: startLocation, location: CLLocation(coordinate: node.coordinate))
            newNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            newNode.position = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            newNode.anchor = ARAnchor(transform: transform)
            sceneView.scene.rootNode.replaceChildNode(node, with: newNode)
            if let anchor = node.anchor { sceneView.session.remove(anchor: anchor) }
            sceneView.session.add(anchor: newNode.anchor!)
            return newNode
        }
    }

    private func setTimerForReconfigure() {
        scheduledTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [unowned self] _ in
            self.sceneView.session.run(self.configuration, options: [.resetTracking, .removeExistingAnchors])
            self.createNodesAndAnchors()
        }
    }

    private func rotateWorldOrigin(withAngle angle: Double) {
        let rotation = MatrixOperations.rotateAroundY(with: matrix_identity_float4x4, for: Float(angle))
        sceneView?.session.setWorldOrigin(relativeTransform: simd_mul(rotation, matrix_identity_float4x4))
    }

    @objc private func dismissARSession() {
        scheduledTimer?.invalidate()
        scheduledTimer = nil
        dismiss(animated: true, completion: nil)
    }
}

extension ARSessionViewController: LocationUpdateDelegate {

    func didReceiveLocationUpdate(to location: CLLocation) {
        if location.horizontalAccuracy <= 30.0 {
            currentLocation = location
            updateNodesAndAnchors()
            distanceTraveled = startLocation.distance(from: currentLocation!)
        }
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

    func failedToUpdateLocation() {
        #warning("display some message")
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
        self.sceneView.session.run(self.configuration, options: [.resetTracking, .removeExistingAnchors])
        self.createNodesAndAnchors()
        setTimerForReconfigure()
    }

}

extension ARSessionViewController: ARSessionDelegate {

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        print(sceneView.pointOfView?.simdWorldPosition.y)
        /// Light estimation
//        print(frame.lightEstimate?.ambientIntensity)

        /// Tracking state information
//        switch frame.camera.trackingState {
//        case .normal:
//            print("normal tracking state")
//        case .limited(let reason):
//            print(reason)
//        case .notAvailable:
//            print("tracking state not available")
//        }

        /// Compare distances
//        let arDistance = sqrt(pow(frame.camera.transform.columns.3.x, 2) + pow(frame.camera.transform.columns.3.z, 2))
//        print(arDistance, distanceTraveled)
    }

}
