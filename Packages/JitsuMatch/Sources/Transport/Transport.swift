//
//  Transport.swift
//  JitsuMatch
//
//  Created by Tom Knighton on 24/02/2026.
//

import Foundation
import JitsuCore

public struct IntentEnvelope: Sendable, Equatable {
    public let seq: UInt64
    public let playerId: Player
    public let intent: Intent
    public let stateHashBefore: UInt64?
    
    public init(seq: UInt64, playerId: Player, intent: Intent, stateHashBefore: UInt64?) {
        self.seq = seq
        self.playerId = playerId
        self.intent = intent
        self.stateHashBefore = stateHashBefore
    }
}
