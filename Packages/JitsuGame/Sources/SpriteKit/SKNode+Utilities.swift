//
//  SKNode+Utilities.swift
//  JitsuGame
//
//  Created by Tom Knighton on 24/02/2026.
//

import SpriteKit

extension SKNode {
    func drawBorder(color: UIColor, width: CGFloat) {
        let shapeNode = SKShapeNode(rect: frame)
        shapeNode.fillColor = .clear
        shapeNode.strokeColor = color
        shapeNode.lineWidth = width
        addChild(shapeNode)
    }
    
    func closestAncestor<T: SKNode>(of _: T.Type) -> T? {
        var n: SKNode? = self
        while let current = n {
            if let t = current as? T { return t }
            n = current.parent
        }
        return nil
    }
}
