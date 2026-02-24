//
//  Intent.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Foundation

public enum Intent: Hashable, Codable, Sendable {
    case selectCard(player: Player, card: CardId)
    case concede(player: Player)
}
