//
//  MatchPhase.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Foundation

public enum MatchPhase: Hashable, Codable, Sendable {
    case dealing
    case selecting
    case revealing
    case matchEnded(winner: Player?)
}
