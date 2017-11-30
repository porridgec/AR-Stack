//
//  Plane.swift
//  AR Stack
//
//  Created by Hahn.Chan on 30/11/2017.
//  Copyright © 2017 Hahn Chan. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class Plane: SCNNode {
    var anchor: ARPlaneAnchor
    var planeGeometry: SCNPlane
    
    init(with anchor: ARPlaneAnchor) {
        self.anchor = anchor
        planeGeometry = SCNPlane.init(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        let material = SCNMaterial()
        material.diffuse.contents = #imageLiteral(resourceName: "tron_grid")
        planeGeometry.materials = [material]
        let planeNode = SCNNode.init(geometry: planeGeometry)
        planeNode.position = SCNVector3.init(anchor.center.x, 0, anchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-(.pi / 2), 1, 0, 0)
        super.init()
        setTextureScale()
        addChildNode(planeNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(with anchor: ARPlaneAnchor) {
        planeGeometry.width = CGFloat(anchor.extent.x)
        planeGeometry.height = CGFloat(anchor.extent.z)
        
        position = SCNVector3.init(anchor.center.x, 0, anchor.center.z)
        setTextureScale()
    }
    
    func setTextureScale() {
        guard let material = planeGeometry.materials.first else {
            return
        }
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(planeGeometry.width), Float(planeGeometry.height), 1)
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
    }
}
