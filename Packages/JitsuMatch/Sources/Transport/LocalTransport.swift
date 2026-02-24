//
//  LocalTransport.swift
//  JitsuMatch
//
//  Created by Tom Knighton on 24/02/2026.
//

import Foundation
import JitsuCore

public actor LocalTransportHub {
    public struct EndpointId: Hashable, Sendable {
        fileprivate let raw: UUID
        fileprivate init(_ raw: UUID) { self.raw = raw }
    }
    
    private let host: LocalHost
    
    private var continuations: [EndpointId: AsyncStream<IntentEnvelope>.Continuation] = [:]
    
    public init(host: LocalHost) {
        self.host = host
    }
    
    public func connect(playerId: Player) -> LocalTransportEndpoint {
        let id = EndpointId(UUID())
        let stream = AsyncStream<IntentEnvelope> { continuation in
            continuation.onTermination = { [weak self] _ in
                Task { await self?.disconnect(id: id) }
            }
            
            self.storeContinuation(continuation, for: id)
        }
        
        return LocalTransportEndpoint(playerID: playerId, id: id, hub: self, stream: stream)
    }
    
    public func submitFromClient(player: Player, intent: Intent, stateHashBefore: UInt64?) async {
        let accepted = await host.accept(player: player, intent: intent, stateHashBefore: stateHashBefore)
        await broadcast(accepted)
    }
    
    private func storeContinuation(_ c: AsyncStream<IntentEnvelope>.Continuation, for id: EndpointId) {
        continuations[id] = c
    }
    
    private func disconnect(id: EndpointId) {
        continuations[id] = nil
    }
    
    private func broadcast(_ envelope: IntentEnvelope) async {
        for continuation in continuations.values {
            continuation.yield(envelope)
        }
    }
}
