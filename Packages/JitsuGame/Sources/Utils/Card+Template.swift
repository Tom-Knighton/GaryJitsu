//
//  Card+Template.swift
//  JitsuGame
//
//  Created by Tom Knighton on 16/03/2026.
//

import JitsuCore
import SpriteKit

public extension CardNode {
    static func template(for card: Card) -> SKTexture {
        switch card.colour {
        case .blue:
            return CardTextureStore.shared.ui(.templateBlue)
        case .red:
            return CardTextureStore.shared.ui(.templateRed)
        case .yellow:
            return CardTextureStore.shared.ui(.templateYellow)
        case .green:
            return CardTextureStore.shared.ui(.templateGreen)
        case .orange:
            return CardTextureStore.shared.ui(.templateOrange)
        case .purple:
            return CardTextureStore.shared.ui(.templatePurple)
        }
    }
    
    static func icon(for card: Card) -> SKTexture {
        switch card.element {
        case .fire:
            return CardTextureStore.shared.ui(.fireIcon)
        case .snow:
            return CardTextureStore.shared.ui(.iceIcon)
        case .water:
            return CardTextureStore.shared.ui(.waterIcon)
        }
    }
}
