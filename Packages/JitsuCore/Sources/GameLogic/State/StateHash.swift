//
//  StateHash.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Foundation
import CryptoKit

public enum StateHash {
    public static func sha256(_ state: GameState) -> String {
        let canonical = CanonicalGameState(state)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        
        do {
            let data = try encoder.encode(canonical)
            let digest = SHA256.hash(data: data)
            return digest.map { String(format: "%02x", $0) }.joined()
        } catch {
            preconditionFailure("Failed to encode canonical state: \(error)")
        }
    }
}

private struct CanonicalGameState: Codable {
    let players: [Player]
    let seed: UInt64
    let initialHandSize: Int
    
    let phase: MatchPhase
    let globalSequence: UInt64
    
    let rng: `Xoshiro256**`
    
    let zones: [CanonicalZone]
    
    let selections: [CanonicalSelection]
    
    init(_ state: GameState) {
        self.players = state.config.players
        self.seed = state.config.seed
        self.initialHandSize = state.config.initialHandSize
        self.phase = state.phase
        self.globalSequence = state.globalSequence
        self.rng = state.rng
        
        self.zones = state.config.players.map { pid in
            let z = state.zones[pid]!
            return CanonicalZone(player: pid, zone: z)
        }
        
        self.selections = state.config.players.compactMap { pid in
            guard let cardId = state.selections.byPlayer[pid] else { return nil }
            return CanonicalSelection(player: pid, cardId: cardId)
        }
    }
    
    struct CanonicalZone: Codable {
        let player: Player
        let deck: [Card]
        let hand: [Card]
        let discard: [Card]
        let tokenAwards: [TokenAward]
        
        init(player: Player, zone: PlayerZone) {
            self.player = player
            self.deck = zone.deck
            self.hand = zone.hand
            self.discard = zone.discard
            self.tokenAwards = zone.tokens.awards
        }
    }
    
    struct CanonicalSelection: Codable {
        let player: Player
        let cardId: CardId
    }
}
