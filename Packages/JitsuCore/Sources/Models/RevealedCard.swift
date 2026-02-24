//
//  RevealedCard.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Foundation

public struct RevealedCard: Hashable, Codable, Sendable {
    public let player: Player
    public let card: Card
    
    public init(player: Player, card: Card) {
        self.player = player
        self.card = card
    }
}
