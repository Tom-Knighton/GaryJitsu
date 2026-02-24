//
//  GameState.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Foundation

public struct GameState: Hashable, Codable, Sendable {
    public let config: MatchData
    public var phase: MatchPhase
    public var zones: [Player: PlayerZone]
    public var selections: RoundSelections
    public var rng: `Xoshiro256**`
    public var globalSequence: UInt64
    
    public init(config: MatchData) {
        self.config = config
        self.phase = .dealing
        self.zones = Dictionary(uniqueKeysWithValues: config.players.map { pid in
            (pid, PlayerZone(deck: config.decks[pid] ?? []))
        })
        self.selections = .init()
        self.rng = .init(seed: config.seed)
        self.globalSequence = 0
    }
    
    public func playerZone(_ player: Player) -> PlayerZone {
        guard let z = zones[player] else { preconditionFailure("Unknown player \(player)") }
        
        return z
    }
}
