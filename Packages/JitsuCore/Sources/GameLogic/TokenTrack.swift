//
//  TokenTrack.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Foundation

/*
 Tracks a player's progress
 */
public struct TokenTrack: Hashable, Codable, Sendable {
    
    public private(set) var awards: [TokenAward]
    
    public init(awards: [TokenAward] = []) {
        self.awards = awards
    }
    
    public mutating func award(from card: Card, sequence: UInt64) {
        self.awards.append(TokenAward(card: card, awardedAtSequence: sequence))
    }
    
    public var counts: [Element: Int] {
        var result: [Element: Int] = [:]
        result.reserveCapacity(Element.allCases.count)
        for a in awards {
            result[a.element, default: 0] += 1
        }
        return result
    }
    
    public func hasThreeOfSame() -> Bool {
        return counts.values.contains(where: { $0 >= 3})
    }
    
    public func hasThreeDifferent() -> Bool {
        return Element.allCases.allSatisfy { (counts[$0] ?? 0) >= 1 }
    }
    
    public func isWinning() -> Bool {
        hasThreeOfSame() || hasThreeDifferent()
    }
}
