//
//  GameConfig.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Foundation

public struct MatchData: Hashable, Codable, Sendable {
    public let players: [Player]
    public let seed: UInt64
    public let initialHandSize: Int
    public let decks: [Player: [Card]]
    public let playIntro: Bool
    
    public init(players: [Player], seed: UInt64, initialHandSize: Int = 5, decks: [Player : [Card]], playIntro: Bool = true) {
        precondition(players.count == Set(players).count, "players must be unique")
        precondition(initialHandSize > 0, "initialHandSize must be > 0")
        precondition(players.allSatisfy { decks[$0] != nil }, "missing deck for player")
        self.players = players
        self.seed = seed
        self.initialHandSize = initialHandSize
        self.decks = decks
        self.playIntro = playIntro
    }
}

public enum MatchDataBuildError: Error, Equatable, Sendable {
    case emptyEligibleCards
    case missingCard(CardId)
}

public enum MatchDataBuilder {
    public static func makeLocalMatch(
        players: [Player],
        seed: UInt64,
        initialHandSize: Int = 5,
        catalog: CardCatalog,
        playIntro: Bool = true
    ) throws -> MatchData {
        let eligibleCards = catalog.cards
        
        guard !eligibleCards.isEmpty else {
            throw MatchDataBuildError.emptyEligibleCards
        }
        
        let decks = Dictionary(uniqueKeysWithValues: players.map { player in
            (player, eligibleCards)
        })
        
        return MatchData(
            players: players,
            seed: seed,
            initialHandSize: initialHandSize,
            decks: decks,
            playIntro: playIntro
        )
    }
    
    public static func makeSharedPoolMatch(
        players: [Player],
        seed: UInt64,
        initialHandSize: Int = 5,
        localCatalog: CardCatalog,
        remoteCatalog: CardCatalog,
        localCollection: PlayerCardCollection? = nil,
        remoteCollection: PlayerCardCollection? = nil,
        playIntro: Bool = true
    ) throws -> MatchData {
        precondition(players.count == 2, "shared-pool match currently expects 2 players")
        
        let p1 = players[0]
        let p2 = players[1]
        
        let localUniverse = localCatalog.allCardIds
        let remoteUniverse = remoteCatalog.allCardIds
        var eligibleIds = localUniverse.intersection(remoteUniverse)
        
        if let localCollection {
            eligibleIds.formIntersection(localCollection.availableCardIds)
        }
        
        if let remoteCollection {
            eligibleIds.formIntersection(remoteCollection.availableCardIds)
        }
        
        guard !eligibleIds.isEmpty else {
            throw MatchDataBuildError.emptyEligibleCards
        }
        
        let eligibleCards = try eligibleIds
            .sorted { $0.rawValue < $1.rawValue }
            .map { id in
                guard let card = localCatalog.card(for: id) else {
                    throw MatchDataBuildError.missingCard(id)
                }
                return card
            }
        
        let decks: [Player: [Card]] = [
            p1: eligibleCards,
            p2: eligibleCards
        ]
        
        return MatchData(
            players: players,
            seed: seed,
            initialHandSize: initialHandSize,
            decks: decks,
            playIntro: playIntro
        )
    }
}
