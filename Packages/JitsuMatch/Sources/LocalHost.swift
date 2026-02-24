//
//  LocalHost.swift
//  JitsuMatch
//
//  Created by Tom Knighton on 24/02/2026.
//

import Foundation
import JitsuCore

public actor LocalHost {
    private var seq: UInt64 = 0
    private var state: GameState
    
    public init(initialState: GameState) {
        self.state = initialState
    }
    
    public func currentState() -> GameState {
        self.state
    }
    
    public func accept(player: Player, intent: Intent, stateHashBefore: UInt64?) -> IntentEnvelope {
        seq &+= 1
        
        let reduced = Engine.reduce(state: state, intent: intent)
        state = reduced.state
        
        return IntentEnvelope(seq: seq, playerId: player, intent: intent, stateHashBefore: stateHashBefore)
    }
}
