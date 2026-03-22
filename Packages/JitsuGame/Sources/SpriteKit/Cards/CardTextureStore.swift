//
//  CardTextureStore.swift
//  JitsuGame
//
//  Created by Tom Knighton on 16/03/2026.
//

@preconcurrency import SpriteKit

final class CardTextureStore: Sendable {
    enum CardTexture: String, CaseIterable {
        case templateRed
        case templateBlue
        case templateOrange
        case templateYellow
        case templateGreen
        case templatePurple
        
        case cardBack
        
        case fireIcon
        case waterIcon
        case iceIcon
    }
    
    static let shared = CardTextureStore()
    
    private let atlas = SKTextureAtlas(named: "Cards")
    private let artAtlas = SKTextureAtlas(named: "CardImages")
    
    func ui(_ texture: CardTexture) -> SKTexture {
        atlas.textureNamed(texture.rawValue)
    }
    
    func preload(textureNames: [String]) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            SKTextureAtlas.preloadTextureAtlases([artAtlas]) {
                cont.resume()
            }
        }
        
        let textures = textureNames.compactMap {
            artAtlas.textureNamed($0)
        }
        
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            SKTexture.preload(textures) {
                cont.resume()
            }
        }
    }
    
    func art(for key: String) -> SKTexture? {
        return artAtlas.textureNamed(key)
    }
}
