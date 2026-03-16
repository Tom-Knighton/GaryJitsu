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
            return CardTextureStore.shared.ui(.blueTemplate)
        case .red:
            return CardTextureStore.shared.ui(.redTemplate)
        case .yellow:
            return CardTextureStore.shared.ui(.yellowTemplate)
        case .green:
            return CardTextureStore.shared.ui(.greenTemplate)
        case .orange:
            return CardTextureStore.shared.ui(.orangeTemplate)
        case .purple:
            return CardTextureStore.shared.ui(.purpleTemplate)
        }
    }
}
