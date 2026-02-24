//
//  TestSupport.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Foundation
import Testing
@testable import JitsuCore

public enum TestSupport {
    public static let p1: Player = "p1"
    public static let p2: Player = "p2"
    
    public static func makeDeck(prefix: String) -> [Card] {
        var cards: [Card] = []
        cards.reserveCapacity(30)
        
        let elements: [Element] = [.fire, .water, .snow]
        var n = 0
        
        for e in elements {
            for p in 1...10 {
                n += 1
                cards.append(Card(id: CardId("\(prefix)\(n)"), element: e, level: p, artKey: "\(e.rawValue)_\(p)"))
            }
        }
        
        return cards
    }
    
    public static func makeConfig(seed: UInt64 = 42, initialHandSize: Int = 5) -> MatchData {
        MatchData(
            players: [p1, p2],
            seed: seed,
            initialHandSize: initialHandSize,
            decks: [
                p1: makeDeck(prefix: "a"),
                p2: makeDeck(prefix: "b"),
            ]
        )
    }
    
    public static func initialState(seed: UInt64 = 42, initialHandSize: Int = 5) -> GameState {
        Engine.makeInitialState(config: makeConfig(seed: seed, initialHandSize: initialHandSize)).state
    }
    
    public static func isInvalid(_ effect: Effect) -> Bool {
        if case .invalidIntent = effect { return true }
        return false
    }
    
    public static func containsInvalid(_ effects: [Effect]) -> Bool {
        effects.contains(where: isInvalid)
    }
}
