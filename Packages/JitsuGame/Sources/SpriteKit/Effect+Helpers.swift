//
//  Effect+Helpers.swift
//  JitsuGame
//
//  Created by Tom Knighton on 24/02/2026.
//

import SpriteKit
import JitsuCore

// MARK: - Effect Array Helpers

extension Array where Element == Effect {
    var firstRevealCards: Effect? {
        first { if case .revealCards = $0 { return true } else { return false } }
    }
    
    var firstAwardToken: (player: Player, award: TokenAward)? {
        for e in self {
            if case let .awardToken(p, a) = e { return (p, a) }
        }
        return nil
    }
    
    var revealPayload: (a: RevealedCard, b: RevealedCard, outcomeForA: CardComparisonResult)? {
        for e in self {
            if case let .revealCards(a, b, outcome) = e { return (a, b, outcome) }
        }
        return nil
    }
}

// MARK: - Element Color Mapping

func colorForElement(_ element: JitsuCore.Element) -> UIColor {
    switch element {
    case .fire:  return UIColor(red: 0.9, green: 0.3, blue: 0.2, alpha: 1.0)
    case .water: return UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)
    case .snow:  return UIColor(red: 0.85, green: 0.9, blue: 1.0, alpha: 1.0)
    }
}
