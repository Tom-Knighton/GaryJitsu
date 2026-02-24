//
//  ReplayAndHashTests.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Testing
@testable import JitsuCore

@Test
func replay_same_seed_same_intents_same_state_and_hash() {
    let cfg = TestSupport.makeConfig(seed: 999, initialHandSize: 5)
    let initial = Engine.makeInitialState(config: cfg).state
    
    func run(_ state: GameState) -> GameState {
        var s = state
        
        for _ in 0..<3 {
            let c1 = s.playerZone(TestSupport.p1).hand[0].id
            let c2 = s.playerZone(TestSupport.p2).hand[0].id
            s = Engine.reduce(state: s, intent: .selectCard(player: TestSupport.p1, card: c1)).state
            s = Engine.reduce(state: s, intent: .selectCard(player: TestSupport.p2, card: c2)).state
            if case .matchEnded = s.phase { break }
        }
        
        return s
    }
    
    let a = run(initial)
    let b = run(initial)
    
    #expect(a == b)
    #expect(StateHash.sha256(a) == StateHash.sha256(b))
}

@Test
func globalSequence_increments_per_reduce_call() {
    var s = TestSupport.initialState()
    let start = s.globalSequence
    
    let c1 = s.playerZone(TestSupport.p1).hand[0].id
    let t1 = Engine.reduce(state: s, intent: .selectCard(player: TestSupport.p1, card: c1))
    #expect(t1.state.globalSequence == start + 1)
    
    let c2 = t1.state.playerZone(TestSupport.p2).hand[0].id
    let t2 = Engine.reduce(state: t1.state, intent: .selectCard(player: TestSupport.p2, card: c2))
    #expect(t2.state.globalSequence == start + 2)
}
