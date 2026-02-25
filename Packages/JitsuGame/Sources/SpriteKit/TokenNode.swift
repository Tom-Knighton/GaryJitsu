//
//  CardNode.swift
//  JitsuGame
//
//  Created by Tom Knighton on 24/02/2026.
//

import SpriteKit
import JitsuCore

public final class TokenNode: SKNode {
    public let cardId: CardId
    public let element: Element
    
    private let rect: SKShapeNode
    private let stripe: SKShapeNode
    private let label: SKLabelNode

    public init(cardId: CardId, size: CGSize, color: UIColor, element: Element) {
        self.cardId = cardId
        
        rect = SKShapeNode(rectOf: size, cornerRadius: 10)
        stripe = SKShapeNode(rectOf: CGSize(width: size.width * 0.9, height: 10), cornerRadius: 4)
        label = SKLabelNode(fontNamed: "SF Pro")
        self.element = element
        
        super.init()
        
        rect.lineWidth = 2
        rect.fillColor = color
        rect.strokeColor = .init(white: 0.25, alpha: 1.0)
        
        stripe.lineWidth = 0
        
        label.fontSize = 30
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        
        switch element {
        case .water:
            label.text = "💧"
        case .fire:
            label.text = "🔥"
        case .snow:
            label.text = "❄️"
        }
        
        stripe.position = CGPoint(x: 0, y: -size.height * 0.18)
        
        addChild(rect)
        addChild(stripe)
        addChild(label)
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }
    
    
    private func shortID(_ id: CardId) -> String {
        let s = String(describing: id.rawValue)
        return String(s)
    }
}
