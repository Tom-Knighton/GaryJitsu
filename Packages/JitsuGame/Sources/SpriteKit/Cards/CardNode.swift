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
    
    private var bgArt: SKSpriteNode
    private var frameArt: SKSpriteNode
    
    private var faceUp: Bool = true
    private var selected: Bool = false
    
    private var elementIcon: SKSpriteNode
    private var levelIcon: SKLabelNode
    
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

        frameArt = SKSpriteNode()
        bgArt = SKSpriteNode()
        elementIcon = SKSpriteNode(texture: Self.icon(for: card))
        levelIcon = SKLabelNode()
        super.init()
        
        drawAndAddBaseNodes(for: cardType)
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }
    
    public func setFaceUp(_ value: Bool) {
        faceUp = value
        
        self.bgArt.isHidden = !faceUp
    }
    
    public func setSelected(_ value: Bool) {
        selected = value
        
        guard action(forKey: "dealing") == nil else { return }
        
        let targetY: CGFloat = selected ? 18 : 0
        if position.y != targetY {
            run(.moveTo(y: targetY, duration: 0.08))
        }
    }
    
    public func setCardType(to cardType: CardType) {
        removeChildren(in: [elementIcon, levelIcon, frameArt])
        frameArt = SKSpriteNode(texture: Self.template(for: card))
        elementIcon = SKSpriteNode(texture: Self.icon(for: card))
        levelIcon = SKLabelNode()
        self.drawAndAddBaseNodes(for: cardType)
    }
    
    private func drawAndAddBaseNodes(for cardType: CardType) {
        if cardType.isFaceUp {
            
            if let art = card.artKey {
                bgArt.texture = CardTextureStore.shared.art(for: art)
                bgArt.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                bgArt.size = .init(width: cardType.size.width - 10, height: cardType.size.height - 10)
                addChild(bgArt)
            }
            
            frameArt.texture = Self.template(for: card)
            frameArt.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            frameArt.size = cardType.size
            addChild(frameArt)
            
            elementIcon.zPosition = 10
            elementIcon.size = .init(width: 12.5, height: 17)
            elementIcon.position = .init(x: cardType.size.width / 3.25, y: cardType.size.height / 3)
            addChild(elementIcon)
            
            levelIcon.zPosition = 10
            levelIcon.text = "\(card.level)"
            levelIcon.fontName = "Kaph-Regular"
            levelIcon.fontSize = 14
            levelIcon.fontColor = .black
            levelIcon.fontColor?.setStroke()
            levelIcon.position = .init(x: cardType.size.width / 3.25, y: cardType.size.height / 25)
            levelIcon.addStroke(color: .white, width: 5)
            addChild(levelIcon)
        } else {
            frameArt.texture = CardTextureStore.shared.ui(.cardBack)
            frameArt.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            frameArt.size = cardType.size
            addChild(frameArt)
        }
        
        setFaceUp(cardType.isFaceUp)
    }
}
