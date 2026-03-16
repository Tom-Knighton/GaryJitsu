//
//  CardTextureStore.swift
//  JitsuGame
//
//  Created by Tom Knighton on 16/03/2026.
//

@preconcurrency import SpriteKit

final class CardTextureStore: Sendable {
    enum CardTexture: String, CaseIterable {
        case redTemplate
        case blueTemplate
        case orangeTemplate
        case yellowTemplate
        case greenTemplate
        case purpleTemplate
        
        case fireIcon
        case waterIcon
        case iceIcon
    }
    
    static let shared = CardTextureStore()
    
    private let atlas = SKTextureAtlas(named: "Cards")
    
    func ui(_ texture: CardTexture) -> SKTexture {
        atlas.textureNamed(texture.rawValue)
    }
}
