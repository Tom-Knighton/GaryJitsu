//
//  CardNode.swift
//  JitsuGame
//
//  Created by Tom Knighton on 24/02/2026.
//

import SpriteKit
import JitsuCore

public final class CardNode: SKNode {
    public let cardId: CardId
    public var isInBottomTray: Bool = false
    public var isDealing: Bool = false
    
    private var rect: SKShapeNode
    private var stripe: SKShapeNode
    private var label: SKLabelNode
    
    private var faceUp: Bool = true
    private var selected: Bool = false
    
    public enum CardType {
        case faceDownSmall
        case faceDownLarge
        case faceUpSmall
        case faceUpLarge
        
        var isFaceUp: Bool {
            self == .faceUpSmall || self == .faceUpLarge
        }
        
        var size: CGSize {
            switch self {
            case .faceUpLarge, .faceDownLarge:
                CGSize(width: 76, height: 110)
            case .faceDownSmall, .faceUpSmall:
                CGSize(width: 44, height: 64)
            }
        }
    }
    
    
    public init(cardId: CardId, cardType: CardType) {
        self.cardId = cardId

        let size = cardType.size
        
        rect = SKShapeNode(rectOf: size, cornerRadius: 10)
        stripe = SKShapeNode(rectOf: CGSize(width: size.width * 0.9, height: 10), cornerRadius: 4)
        label = SKLabelNode(fontNamed: "SF Pro")
        
        super.init()
        
        rect.lineWidth = 2
        rect.strokeColor = .init(white: 0.25, alpha: 1.0)
        
        stripe.lineWidth = 0
        
        label.fontSize = 10
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        
        stripe.position = CGPoint(x: 0, y: -size.height * 0.18)
        
        addChild(rect)
        addChild(stripe)
        addChild(label)
        
        setFaceUp(cardType.isFaceUp)
        setSelected(false)
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }
    
    public func setFaceUp(_ value: Bool) {
        faceUp = value
        
        if faceUp {
            rect.fillColor = .init(white: 0.92, alpha: 1.0)
            stripe.fillColor = .init(white: 0.75, alpha: 1.0)
            label.fontColor = .black
            label.text = cardId.shortID
        } else {
            rect.fillColor = .init(white: 0.20, alpha: 1.0)
            stripe.fillColor = .init(white: 0.30, alpha: 1.0)
            label.fontColor = .init(white: 0.8, alpha: 1.0)
            label.text = " "
        }
    }
    
    public func setSelected(_ value: Bool) {
        selected = value
        
        rect.strokeColor = selected ? .systemYellow : .init(white: 0.25, alpha: 1.0)
        rect.lineWidth = selected ? 3 : 2
        
        guard action(forKey: "dealing") == nil else { return }
        
        let targetY: CGFloat = selected ? 18 : 0
        if position.y != targetY {
            run(.moveTo(y: targetY, duration: 0.08))
        }
    }
    
    public func setCardType(to cardType: CardType) {
        let size = cardType.size
        removeChildren(in: [rect, stripe, label])

        rect = SKShapeNode(rectOf: size, cornerRadius: 10)
        stripe = SKShapeNode(rectOf: CGSize(width: size.width * 0.9, height: 10), cornerRadius: 4)
        label = SKLabelNode(fontNamed: "SF Pro")
        
        rect.lineWidth = 2
        rect.strokeColor = .init(white: 0.25, alpha: 1.0)
        
        stripe.lineWidth = 0
        
        label.fontSize = 10
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        
        stripe.position = CGPoint(x: 0, y: -size.height * 0.18)
        
        addChild(rect)
        addChild(stripe)
        addChild(label)
        
        setFaceUp(cardType.isFaceUp)
    }
}
