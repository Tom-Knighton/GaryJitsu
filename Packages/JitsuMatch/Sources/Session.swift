//
//  Session.swift
//  JitsuMatch
//
//  Created by Tom Knighton on 24/02/2026.
//

import Foundation
import JitsuCore

@MainActor
@Observable
public final class Session {
    
    public private(set) var state: GameState
    public private(set) var lastAppliedSeq: UInt64 = 0

    private let endpoint: any TransportEndpoint
    private var listenTask: Task<Void, Never>?
        
    public init(initialState: GameState, endpoint: any TransportEndpoint) {
        self.state = initialState
        self.endpoint = endpoint
    }
    
    public func start() {
        guard listenTask == nil else { return }
        
        listenTask = Task { [weak self] in
            guard let self else { return }
            
            for await env in self.endpoint.incomingEnvelopes() {
                await self.applyFromHost(env)
            }
        }
    }
    
    public func stop() {
        listenTask?.cancel()
        listenTask = nil
    }
    
    public func submit(_ intent: Intent, stateHashBefore: UInt64? = nil) {
        Task {
            await endpoint.send(intent, stateHashBefore: stateHashBefore)
        }
    }
    
    private func applyFromHost(_ env: IntentEnvelope) async {
        guard env.seq > lastAppliedSeq else { return }
        
        if env.seq != lastAppliedSeq &+ 1 {
            // TODO: Resync/Snapshot
            lastAppliedSeq = env.seq
        } else {
            lastAppliedSeq = env.seq
        }
        
        let reduced = Engine.reduce(state: state, intent: env.intent)
        state = reduced.state
    }
}
