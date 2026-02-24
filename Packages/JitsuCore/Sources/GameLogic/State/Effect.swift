//
//  Effect.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Foundation

public enum Effect: Hashable, Codable, Sendable {
    case dealtInitialHands(handSize: Int)
    case cardSelected(player: Player, card: CardId)
    case revealCards(
        a: RevealedCard,
        b: RevealedCard,
        outcomeForA: CardComparisonResult
    )
    case awardToken(player: Player, award: TokenAward)
    case discard(cards: [CardId])
    case draw(player: Player, card: CardId)
    case roundEnded
    case matchEnded(winner: Player?)
    case invalidIntent(reason: String)
}
