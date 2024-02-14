//
//  DefaultRedShapeNode.swift
//  TrafficDevilsTestTask
//
//  Created by Vitya Mandryk on 14.02.2024.
//

import Foundation
import UIKit
import SpriteKit

class DefaultRedShapeNode: SKShapeNode {
    
    init(size: CGFloat) {
        super.init()
        self.path = createTrianglePath(size: size)
        self.physicsBody = createPhysicsBody()
        self.fillColor = SKColor.red
        self.strokeColor = SKColor.white
        self.lineWidth = 2.0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createTrianglePath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: -size / 2))
        path.addLine(to: CGPoint(x: -size / 2, y: size / 2))
        path.addLine(to: CGPoint(x: size / 2, y: size / 2))
        path.closeSubpath()
        return path
    }
    
    private func createPhysicsBody() -> SKPhysicsBody {
        let body = SKPhysicsBody(rectangleOf: self.frame.size)
        body.collisionBitMask = 0
        body.affectedByGravity = false
        return body
    }
}

