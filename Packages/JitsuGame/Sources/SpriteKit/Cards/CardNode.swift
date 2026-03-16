//
//  CardNode.swift
//  JitsuGame
//
//  Created by Tom Knighton on 24/02/2026.
//

import SpriteKit
import JitsuCore

public final class CardNode: SKNode {
    public let card: Card
    public var isInBottomTray: Bool = false
    public var isDealing: Bool = false
    
    private var frameArt: SKSpriteNode
    
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
    
    
    public init(card: Card, cardType: CardType) {
        self.card = card

        rect = SKShapeNode(rectOf: cardType.size, cornerRadius: 10)
        stripe = SKShapeNode(rectOf: CGSize(width: cardType.size.width * 0.9, height: 10), cornerRadius: 4)
        label = SKLabelNode(fontNamed: "SF Pro")
        frameArt = SKSpriteNode(texture: Self.template(for: card))
        super.init()
        
        drawAndAddBaseNodes(for: cardType)
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }
    
    public func setFaceUp(_ value: Bool) {
        faceUp = value
        
        if faceUp {
            rect.fillColor = .init(white: 0.92, alpha: 1.0)
            stripe.fillColor = colour(for: card.colour)
            label.fontColor = .black
            label.text = card.id.shortID
            frameArt.isHidden = false
        } else {
            rect.fillColor = .init(white: 0.20, alpha: 1.0)
            stripe.fillColor = colour(for: card.colour)
            label.fontColor = .init(white: 0.8, alpha: 1.0)
            label.text = " "
            frameArt.isHidden = true
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
        removeChildren(in: [rect, stripe, label])
        rect = SKShapeNode(rectOf: cardType.size, cornerRadius: 10)
        stripe = SKShapeNode(rectOf: CGSize(width: cardType.size.width * 0.9, height: 10), cornerRadius: 4)
        label = SKLabelNode(fontNamed: "SF Pro")
        frameArt = SKSpriteNode(texture: Self.template(for: card))
        self.drawAndAddBaseNodes(for: cardType)
    }
    
    private func drawAndAddBaseNodes(for cardType: CardType) {
        rect.lineWidth = 2
        rect.strokeColor = .init(white: 0.25, alpha: 1.0)
        
        stripe.lineWidth = 0
        
        label.fontSize = 10
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        
        stripe.position = CGPoint(x: 0, y: -cardType.size.height * 0.18)
        
        if cardType.isFaceUp {
            frameArt.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            frameArt.size = cardType.size
            addChild(frameArt)
        } else {
            addChild(rect)
            addChild(stripe)
        }
        
        addChild(label)
        setFaceUp(cardType.isFaceUp)
    }
}
