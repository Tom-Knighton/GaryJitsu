//
//  EngineInitTests.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Testing
@testable import JitsuCore

@Test
func engine_makeInitialState_deals_hands_and_sets_phase() {
    let cfg = TestSupport.makeConfig(seed: 42, initialHandSize: 5)
    let t = Engine.makeInitialState(config: cfg)
    let s = t.state
    
    #expect(s.phase == .selecting)
    #expect(s.playerZone(TestSupport.p1).hand.count == 5)
    #expect(s.playerZone(TestSupport.p2).hand.count == 5)
    
    #expect(s.playerZone(TestSupport.p1).deck.count == 25)
    #expect(s.playerZone(TestSupport.p2).deck.count == 25)
    
    #expect(!TestSupport.containsInvalid(t.effects))
    #expect(t.effects.first == .dealtInitialHands(handSize: 5))
}

@Test
func engine_makeInitialState_is_deterministic_for_seed() {
    let cfg = TestSupport.makeConfig(seed: 777, initialHandSize: 5)
    
    let a = Engine.makeInitialState(config: cfg).state
    let b = Engine.makeInitialState(config: cfg).state
    
    #expect(a == b)
    #expect(StateHash.sha256(a) == StateHash.sha256(b))
}

@Test
func engine_makeInitialState_changes_with_different_seed() {
    let a = Engine.makeInitialState(config: TestSupport.makeConfig(seed: 1)).state
    let b = Engine.makeInitialState(config: TestSupport.makeConfig(seed: 2)).state
    
    let aHand = a.playerZone(TestSupport.p1).hand.map(\.id)
    let bHand = b.playerZone(TestSupport.p1).hand.map(\.id)
    
    #expect(StateHash.sha256(a) != StateHash.sha256(b) || aHand != bHand)
}
