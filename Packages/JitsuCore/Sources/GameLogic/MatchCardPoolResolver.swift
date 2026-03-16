//
//  MatchCardPoolResolver.swift
//  JitsuCore
//
//  Created by Tom Knighton on 16/03/2026.
//


public enum MatchCardPoolResolver {
    public static func eligibleCards(
        localCatalog: CardCatalog,
        remoteCatalog: CardCatalog,
        localCollection: PlayerCardCollection? = nil,
        remoteCollection: PlayerCardCollection? = nil
    ) throws -> [Card] {
        let localUniverse = localCatalog.allCardIds
        let remoteUniverse = remoteCatalog.allCardIds
        
        let sharedUniverse = localUniverse.intersection(remoteUniverse)
        
        guard !sharedUniverse.isEmpty else {
            throw CardCatalogError.emptyEligiblePool
        }
        
        let localAvailable = localCollection?.availableCardIds ?? localUniverse
        let remoteAvailable = remoteCollection?.availableCardIds ?? remoteUniverse
        
        let eligibleIds = sharedUniverse
            .intersection(localAvailable)
            .intersection(remoteAvailable)
        
        guard !eligibleIds.isEmpty else {
            throw CardCatalogError.emptyEligiblePool
        }
        
        return eligibleIds
            .compactMap { localCatalog.card(for: $0) }
            .sorted { $0.id.rawValue < $1.id.rawValue }
    }
}
