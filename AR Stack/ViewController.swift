//
//  ViewController.swift
//  AR Stack
//
//  Created by Hahn.Chan on 28/09/2017.
//  Copyright © 2017 Hahn Chan. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

struct CollisionCategory {
    static let plane = 1 << 0
    static let box = 1 << 1
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var planeNode: SCNNode?
    var originBookNode: SCNNode?
    var planes: [UUID: Plane] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        scene.physicsWorld.contactDelegate = self
        // Set the scene to the view
        sceneView.scene = scene
        originBookNode = scene.rootNode.childNode(withName: "book", recursively: true)
        originBookNode?.geometry?.materials[0].diffuse.contents = UIColor.white
        for _ in 1...5 {
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.white
            originBookNode?.geometry?.materials.append(material)
        }
        originBookNode?.geometry?.materials[4].diffuse.contents = "art.scnassets/book.jpg"
        originBookNode?.geometry?.materials[3].diffuse.contents = UIColor.red
        originBookNode?.geometry?.materials[5].diffuse.contents = UIColor.red
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.isLightEstimationEnabled = true
//        configuration.worldAlignment = .gravityAndHeading

        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        let plane = Plane.init(with: planeAnchor)
        planes[anchor.identifier] = plane
        node.addChildNode(plane)
        
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let plane = planes[anchor.identifier] else {
            return
        }
        plane.update(with: anchor as! ARPlaneAnchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        planes.removeValue(forKey: anchor.identifier)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        let results = sceneView.hitTest(touch.location(in: sceneView), types: [ARHitTestResult.ResultType.existingPlaneUsingExtent])
        guard let hitFeature = results.last else { return }
//        insertGeometry(hitResult: hitFeature)
        insertBook(hitResult: hitFeature)
    }
    
    func insertBook(hitResult: ARHitTestResult) {
        guard let node = originBookNode?.clone() else { return }
        node.physicsBody = SCNPhysicsBody.init(type: .dynamic,
                                               shape: SCNPhysicsShape.init(geometry: node.geometry!,
                                                                           options: nil))
        node.physicsBody?.mass = 0.1
        node.physicsBody?.categoryBitMask = CollisionCategory.box
        
        let insertionYOffset: Float = 0.125
        node.position = SCNVector3.init(x: hitResult.worldTransform.columns.3.x,
                                        y: hitResult.worldTransform.columns.3.y + insertionYOffset,
                                        z: hitResult.worldTransform.columns.3.z)
        
        sceneView.scene.rootNode.addChildNode(node)
    }

    func insertGeometry(hitResult: ARHitTestResult) {
        let dimension: CGFloat = 0.01
        let cube = SCNBox.init(width: dimension,
                               height: dimension,
                               length: dimension,
                               chamferRadius: 0)
        let node = SCNNode.init(geometry: cube)
        node.physicsBody = SCNPhysicsBody.init(type: .dynamic,
                                               shape: SCNPhysicsShape.init(geometry: cube,
                                                                           options: nil))
        node.physicsBody?.mass = 0.1
        node.physicsBody?.categoryBitMask = CollisionCategory.box

        let insertionYOffset: Float = 0.125
        node.position = SCNVector3.init(x: hitResult.worldTransform.columns.3.x,
                                        y: hitResult.worldTransform.columns.3.y + insertionYOffset,
                                        z: hitResult.worldTransform.columns.3.z)

        sceneView.scene.rootNode.addChildNode(node)
    }
}

extension ViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let mask = contact.nodeA.categoryBitMask | contact.nodeB.categoryBitMask

        if mask == (CollisionCategory.plane | CollisionCategory.box) {
            if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.plane {
                contact.nodeB.removeFromParentNode()
            } else {
                contact.nodeA.removeFromParentNode()
            }
        }
    }
}

