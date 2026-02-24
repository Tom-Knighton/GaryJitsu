//
//  GameState+MatchAccessors.swift
//  JitsuMatch
//
//  Created by Tom Knighton on 24/02/2026.
//

import Foundation
import JitsuCore

public extension GameState {
    
    @inlinable
    func zone(_ player: Player) -> PlayerZone {
        playerZone(player)
    }
    
    @inlinable
    func hand(_ player: Player) -> [Card] {
        zone(player).hand
    }
    
    @inlinable
    func handIds(_ player: Player) -> [CardId] {
        zone(player).hand.map(\.id)
    }
    
    @inlinable
    func selectedCardId(_ player: Player) -> CardId? {
        selections.selectedCardId(for: player)
    }
    
    @inlinable
    var allPlayersHaveSelected: Bool {
        config.players.allSatisfy { selections.selectedCardId(for: $0) != nil }
    }
    
    @inlinable
    func tokenCount(_ player: Player) -> Int {
        zone(player).tokenCount
    }
    
    @inlinable
    var isDealing: Bool {
        if case .dealing = phase { return true }
        return false
    }
    
    @inlinable
    var isRoundInProgress: Bool {
        switch phase {
        case .selecting, .revealing:
            return true
        default:
            return false
        }
    }
    
    @inlinable
    var isMatchEnded: Bool {
        if case .matchEnded = phase { return true }
        return false
    }
}

public extension RoundSelections {
    
    @inlinable
    func selectedCardId(for player: Player) -> CardId? {
        byPlayer[player]
    }
}

public extension PlayerZone {
    @inlinable
    var tokenCount: Int {
        tokens.awards.count
    }
}
