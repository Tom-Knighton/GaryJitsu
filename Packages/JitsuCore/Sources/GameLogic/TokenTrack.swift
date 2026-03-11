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
    
    public struct TokenEntryType: Hashable, Codable, Sendable, ExpressibleByStringLiteral {
        let element: Element
        let colour: Card.Colour
        
        public init(element: Element, colour: Card.Colour) {
            self.element = element
            self.colour = colour
        }
        
        public init(stringLiteral value: StringLiteralType) {
            let parts = value.split(separator: "_")
            self.element = Element(rawValue: String(parts[0])) ?? .fire
            self.colour = Card.Colour(rawValue: String(parts[1])) ?? .red
        }
        
        public var rawValue: String { element.rawValue + "_" + colour.rawValue }
    }
    
    public private(set) var awards: [TokenAward]
    
    public init(awards: [TokenAward] = []) {
        self.awards = awards
    }
    
    public mutating func award(from card: Card, sequence: UInt64) {
        self.awards.append(TokenAward(card: card, awardedAtSequence: sequence))
    }
    
    public var counts: [TokenEntryType: Int] {
        var result: [TokenEntryType: Int] = [:]
//        result.reserveCapacity(Element.allCases.count)
        for a in awards {
            result[.init(element: a.element, colour: a.colour), default: 0] += 1
        }
        return result
    }
    
    /// Whether the user has three of the same element in different colours
    public func hasThreeOfSameElementDifferentColours() -> Bool {
        let presentEntries = counts.lazy
            .filter { $0.value > 0 }
            .map(\.key)
        
        var coloursByElement: [Element: Set<Card.Colour>] = [:]
        
        for entry in presentEntries {
            coloursByElement[entry.element, default: []].insert(entry.colour)
        }
        
        return coloursByElement.values.contains { $0.count >= 3 }
    }
    
    /// Whether the user has three cards of different elements, in different colours
    public func hasThreeDifferentElementsDifferentColours() -> Bool {
        let presentEntries = counts.lazy.filter { $0.value > 0 }.map(\.key)
        var coloursByElement: [Element: Set<Card.Colour>] = [:]
        
        for entry in presentEntries {
            coloursByElement[entry.element, default: []].insert(entry.colour)
        }
        
        let allElements = Array(Element.allCases)
        
        guard allElements.count <= Card.Colour.allCases.count else {
            return false
        }
        
        guard allElements.allSatisfy({ !(coloursByElement[$0] ?? []).isEmpty }) else {
            return false
        }
        
        let orderedElements = allElements.sorted {
            (coloursByElement[$0]?.count ?? 0) < (coloursByElement[$1]?.count ?? 0)
        }
        
        var usedColours = Set<Card.Colour>()
        
        func search(from index: Int) -> Bool {
            if index == orderedElements.count {
                return true
            }
            
            let element = orderedElements[index]
            guard let availableColours = coloursByElement[element] else {
                return false
            }
            
            for colour in availableColours {
                guard !usedColours.contains(colour) else { continue }
                
                usedColours.insert(colour)
                defer { usedColours.remove(colour) }
                
                if search(from: index + 1) {
                    return true
                }
            }
            
            return false
        }
        
        return search(from: 0)
    }
    
    public func isWinning() -> Bool {
        hasThreeDifferentElementsDifferentColours() || hasThreeOfSameElementDifferentColours()
    }
}
