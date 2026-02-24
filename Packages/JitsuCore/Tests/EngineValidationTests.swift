//
//  EngineValidationTests.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Testing
@testable import JitsuCore

@Test
func selecting_unknown_player_is_invalid() {
    let s = TestSupport.initialState()
    let t = Engine.reduce(state: s, intent: .selectCard(player: "nope", card: "a1"))
    
    #expect(TestSupport.containsInvalid(t.effects))
}

@Test
func selecting_card_not_in_hand_is_invalid() {
    let s = TestSupport.initialState()
    let t = Engine.reduce(state: s, intent: .selectCard(player: TestSupport.p1, card: "not-real"))
    
    #expect(TestSupport.containsInvalid(t.effects))
}

@Test
func selecting_twice_in_same_round_is_invalid() {
    var s = TestSupport.initialState()
    let firstCard = s.playerZone(TestSupport.p1).hand[0].id
    s = Engine.reduce(state: s, intent: .selectCard(player: TestSupport.p1, card: firstCard)).state
    
    let secondCard = s.playerZone(TestSupport.p1).hand[0].id
    let t2 = Engine.reduce(state: s, intent: .selectCard(player: TestSupport.p1, card: secondCard))
    
    #expect(TestSupport.containsInvalid(t2.effects))
}

@Test
func cannot_act_when_match_ended() {
    var s = TestSupport.initialState()
    s.phase = .matchEnded(winner: TestSupport.p1)
    
    let t = Engine.reduce(state: s, intent: .selectCard(player: TestSupport.p2, card: "b1"))
    #expect(TestSupport.containsInvalid(t.effects))
}
