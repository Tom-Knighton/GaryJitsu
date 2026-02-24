//
//  MatchState.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Foundation

public struct PlayerZone: Hashable, Codable, Sendable {
    public var deck: [Card]
    public var hand: [Card]
    public var discard: [Card]
    public var tokens: TokenTrack
    
    public init(deck: [Card], hand: [Card] = [], discard: [Card] = [], tokens: TokenTrack = .init()) {
        self.deck = deck
        self.hand = hand
        self.discard = discard
        self.tokens = tokens
    }
}
