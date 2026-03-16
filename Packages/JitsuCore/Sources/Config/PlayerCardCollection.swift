//
//  PlayerCardCollection.swift
//  JitsuCore
//
//  Created by Tom Knighton on 16/03/2026.
//


public struct PlayerCardCollection: Hashable, Codable, Sendable {
    public let availableCardIds: Set<CardId>

    public init(availableCardIds: Set<CardId>) {
        self.availableCardIds = availableCardIds
    }

    public static func all(from catalog: CardCatalog) -> Self {
        .init(availableCardIds: catalog.allCardIds)
    }
}
