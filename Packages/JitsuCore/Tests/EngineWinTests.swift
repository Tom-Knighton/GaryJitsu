//
//  EngineWinTests.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Testing
@testable import JitsuCore

@Test
func match_ends_when_player_has_three_of_same_element_with_different_colours() {
    var s = TestSupport.initialState(seed: 1, initialHandSize: 1)
    let p1 = TestSupport.p1
    let p2 = TestSupport.p2
    
    // Preload tokens so next win is the third Snow token.
    var z1 = s.playerZone(p1)
    z1.tokens.award(from: Card(id: "t1", element: .snow, level: 1, colour: .red), sequence: 1)
    z1.tokens.award(from: Card(id: "t2", element: .snow, level: 2, colour: .blue), sequence: 1)
    s.zones[p1] = z1
    
    // Force hands so p1 wins with Snow (Snow beats Water).
    var zA = s.playerZone(p1)
    var zB = s.playerZone(p2)
    zA.hand = [Card(id: "p1_snow", element: .snow, level: 1, colour: .green)]
    zB.hand = [Card(id: "p2_water", element: .water, level: 10, colour: .red)]
    s.zones[p1] = zA
    s.zones[p2] = zB
    
    s = Engine.reduce(state: s, intent: .selectCard(player: p1, card: "p1_snow")).state
    let t2 = Engine.reduce(state: s, intent: .selectCard(player: p2, card: "p2_water"))
    
    // Must be ended with p1 winner.
    if case let .matchEnded(winner) = t2.state.phase {
        #expect(winner == p1)
    } else {
        #expect(Bool(false))
    }
    
    #expect(t2.effects.contains(where: { if case let .matchEnded(winner) = $0 { winner == p1 } else { false } }))
}

@Test
func match_ends_when_player_has_three_different_elements_different_colours() {
    var s = TestSupport.initialState(seed: 1, initialHandSize: 1)
    let p1 = TestSupport.p1
    let p2 = TestSupport.p2
    
    // Preload tokens so next win completes Fire+Water+Snow.
    var z1 = s.playerZone(p1)
    z1.tokens.award(from: Card(id: "t1", element: .fire, level: 1, colour: .red), sequence: 1)
    z1.tokens.award(from: Card(id: "t2", element: .water, level: 1, colour: .blue), sequence: 1)
    s.zones[p1] = z1
    
    // Force hands so p1 wins with Snow (Snow beats Water).
    var zA = s.playerZone(p1)
    var zB = s.playerZone(p2)
    zA.hand = [Card(id: "p1_snow", element: .snow, level: 1, colour: .green)]
    zB.hand = [Card(id: "p2_water", element: .water, level: 10, colour: .red)]
    s.zones[p1] = zA
    s.zones[p2] = zB
    
    s = Engine.reduce(state: s, intent: .selectCard(player: p1, card: "p1_snow")).state
    let t2 = Engine.reduce(state: s, intent: .selectCard(player: p2, card: "p2_water"))
    
    if case let .matchEnded(winner) = t2.state.phase {
        #expect(winner == p1)
    } else {
        #expect(Bool(false))
    }
}
