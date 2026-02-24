//
//  EngineConcedeTests.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Testing
@testable import JitsuCore

@Test
func concede_ends_match_and_declares_other_player_winner() {
    let s = TestSupport.initialState(seed: 42, initialHandSize: 5)
    let t = Engine.reduce(state: s, intent: .concede(player: TestSupport.p1))
    
    if case let .matchEnded(winner) = t.state.phase {
        #expect(winner == TestSupport.p2)
    } else {
        #expect(false)
    }
    
    #expect(t.effects.contains(where: { if case let .matchEnded(winner) = $0 { winner == TestSupport.p2 } else { false } }))
}

@Test
func concede_from_unknown_player_is_invalid() {
    let s = TestSupport.initialState()
    let t = Engine.reduce(state: s, intent: .concede(player: "unknown"))
    
    #expect(TestSupport.containsInvalid(t.effects))
}
