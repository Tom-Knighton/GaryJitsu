//
//  RoundSelections.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Foundation

public struct RoundSelections: Hashable, Codable, Sendable {
    public var byPlayer: [Player: CardId]
    
    public init(byPlayer: [Player : CardId] = [:]) {
        self.byPlayer = byPlayer
    }
    
    public func isComplete(for players: [Player]) -> Bool {
        players.allSatisfy { byPlayer[$0] != nil }
    }
}
