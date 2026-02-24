//
//  TokenAward.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Foundation

/**
 Represents a snapshot of a card awarded to a player as part of their token track
 */
public struct TokenAward: Hashable, Codable, Sendable {
    public let cardId: CardId
    public let element: Element
    public let level: Int
    public let artKey: String?
    public let awardedAtSequence: UInt64
    
    public init(card: Card, awardedAtSequence: UInt64) {
        self.cardId = card.id
        self.element = card.element
        self.level = card.level
        self.artKey = card.artKey
        self.awardedAtSequence = awardedAtSequence
    }
}
