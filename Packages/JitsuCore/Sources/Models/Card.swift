//
//  Card.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Foundation

public struct CardId: Hashable, Codable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: StringLiteralType) { self.rawValue = value }
}

public struct Card: Hashable, Codable, Sendable {
    public let id: CardId
    public let name: String
    public let description: String?
    public let element: Element
    public let level: Int
    public let artKey: String?
    public let colour: Colour
    
    public enum Colour: String, Hashable, Codable, Sendable, CaseIterable {
        case red, blue, yellow, green, orange, purple
    }
    
    public init(id: CardId, name: String, description: String? = nil, element: Element, level: Int, colour: Colour, artKey: String? = nil) {
        self.id = id
        self.element = element
        self.level = level
        self.artKey = artKey
        self.colour = colour
        self.name = name
        self.description = description
    }
}
