//
//  CardCatalog.swift
//  JitsuCore
//
//  Created by Tom Knighton on 16/03/2026.
//

import Foundation

public struct CardCatalog: Hashable, Sendable {
    public let schemaVersion: Int
    public let catalogVersion: String
    public let cards: [Card]
    
    private let cardsById: [CardId: Card]
    
    public init(schemaVersion: Int, catalogVersion: String, cards: [Card]) throws {
        let grouped = Dictionary(grouping: cards, by: \.id)
        let duplicateIds = grouped.compactMap { $1.count > 1 ? $0 : nil }
        
        guard duplicateIds.isEmpty else {
            throw CardCatalogError.duplicateCardIds(duplicateIds.sorted { $0.rawValue < $1.rawValue })
        }
        
        self.schemaVersion = schemaVersion
        self.catalogVersion = catalogVersion
        self.cards = cards
        self.cardsById = Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0) })
    }
    
    public func card(for id: CardId) -> Card? {
        cardsById[id]
    }
    
    public var allCardIds: Set<CardId> {
        Set(cardsById.keys)
    }
}

public enum CardCatalogError: Error, Equatable, Sendable {
    case duplicateCardIds([CardId])
    case unknownCardIds([CardId])
    case emptyEligiblePool
    case unsupportedSchemaVersion(Int)
    case decodeFailed(String)
}

struct CardCatalogDTO: Decodable {
    let schemaVersion: Int
    let catalogVersion: String
    let cards: [CardDTO]
}

struct CardDTO: Decodable {
    let id: String
    let setId: String?
    let name: String
    let description: String?
    let element: Element
    let level: Int
    let colour: Card.Colour
    let artKey: String?
}

public enum CardCatalogDecoder {
    public static func decode(from data: Data) throws -> CardCatalog {
        let dto: CardCatalogDTO
        
        do {
            dto = try JSONDecoder().decode(CardCatalogDTO.self, from: data)
        } catch {
            throw CardCatalogError.decodeFailed(String(describing: error))
        }
        
        guard dto.schemaVersion == 1 else {
            throw CardCatalogError.unsupportedSchemaVersion(dto.schemaVersion)
        }
        
        let cards = dto.cards.map {
            Card(
                id: CardId($0.id),
                name: $0.name,
                description: $0.description,
                element: $0.element,
                level: $0.level,
                colour: $0.colour,
                artKey: $0.artKey
            )
        }
        
        return try CardCatalog(
            schemaVersion: dto.schemaVersion,
            catalogVersion: dto.catalogVersion,
            cards: cards
        )
    }
}
