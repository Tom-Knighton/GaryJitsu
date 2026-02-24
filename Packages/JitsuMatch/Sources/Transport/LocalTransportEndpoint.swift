//
//  LocalTransportEndpoint.swift
//  JitsuMatch
//
//  Created by Tom Knighton on 24/02/2026.
//

import Foundation
import JitsuCore

public struct LocalTransportEndpoint: TransportEndpoint {
    public let playerId: Player

    fileprivate let id: LocalTransportHub.EndpointId
    fileprivate let hub: LocalTransportHub
    fileprivate let stream: AsyncStream<IntentEnvelope>

    init(
        playerID: Player,
        id: LocalTransportHub.EndpointId,
        hub: LocalTransportHub,
        stream: AsyncStream<IntentEnvelope>
    ) {
        self.playerId = playerID
        self.id = id
        self.hub = hub
        self.stream = stream
    }

    public func send(_ intent: Intent, stateHashBefore: UInt64? = nil) async {
        await hub.submitFromClient(player: playerId, intent: intent, stateHashBefore: stateHashBefore)
    }

    public func incomingEnvelopes() -> AsyncStream<IntentEnvelope> {
        stream
    }
}
