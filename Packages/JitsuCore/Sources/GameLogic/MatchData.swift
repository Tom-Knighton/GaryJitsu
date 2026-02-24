//
//  GameConfig.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Foundation

public struct MatchData: Hashable, Codable, Sendable {
    public let players: [Player]
    public let seed: UInt64
    public let initialHandSize: Int
    public let decks: [Player: [Card]]
    
    public init(players: [Player], seed: UInt64, initialHandSize: Int = 5, decks: [Player : [Card]]) {
        precondition(players.count == Set(players).count, "players must be unique")
        precondition(initialHandSize > 0, "initialHandSize must be > 0")
        precondition(players.allSatisfy { decks[$0] != nil }, "missing deck for player")
        self.players = players
        self.seed = seed
        self.initialHandSize = initialHandSize
        self.decks = decks
    }
}
