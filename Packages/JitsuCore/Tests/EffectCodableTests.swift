//
//  EffectCodableTests.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

// Tests/JitsuCoreTests/EffectCodableTests.swift

import Foundation
import Testing
@testable import JitsuCore

@Test
func effect_is_codable_round_trip() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    let decoder = JSONDecoder()
    
    let cardA = Card(id: "a1", element: .fire, level: 3, artKey: "fire_3")
    let cardB = Card(id: "b1", element: .snow, level: 9, artKey: "snow_9")
    
    let effect: Effect = .revealCards(
        a: .init(player: TestSupport.p1, card: cardA),
        b: .init(player: TestSupport.p2, card: cardB),
        outcomeForA: .win
    )
    
    let data = try encoder.encode(effect)
    let decoded = try decoder.decode(Effect.self, from: data)
    
    #expect(decoded == effect)
}

@Test
func gameState_is_codable_round_trip() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    let decoder = JSONDecoder()
    
    let s = TestSupport.initialState(seed: 123, initialHandSize: 5)
    
    let data = try encoder.encode(s)
    let decoded = try decoder.decode(GameState.self, from: data)
    
    #expect(decoded == s)
}
