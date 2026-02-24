//
//  TransportEndpoint.swift
//  JitsuMatch
//
//  Created by Tom Knighton on 24/02/2026.
//

import Foundation
import JitsuCore

public protocol TransportEndpoint: Sendable {
    var playerId: Player { get }
    
    func send(_ intent: Intent, stateHashBefore: UInt64?) async
    func incomingEnvelopes() -> AsyncStream<IntentEnvelope>
}
