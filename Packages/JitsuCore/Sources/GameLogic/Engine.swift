//
//  Engine.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Foundation

public struct Transition: Hashable, Codable, Sendable {
    public var state: GameState
    public var effects: [Effect]
    
    public init(state: GameState, effects: [Effect]) {
        self.state = state
        self.effects = effects
    }
}

public enum Engine {
    public static func makeInitialState(config: MatchData) -> Transition {
        var state = GameState(config: config)
        
        for pid in config.players {
            guard var zone = state.zones[pid] else { continue }
            state.rng.shuffle(&zone.deck)
            state.zones[pid] = zone
        }
        
        var effects: [Effect] = []
        for pid in config.players {
            for _ in 0..<config.initialHandSize {
                if let drawn = drawTopCard(&state, player: pid) {
                    effects.append(.draw(player: pid, card: drawn.id))
                }
            }
        }
        
        state.phase = .selecting
        effects.insert(.dealtInitialHands(handSize: config.initialHandSize), at: 0)
        return Transition(state: state, effects: effects)
    }
    
    public static func reduce(state: GameState, intent: Intent) -> Transition {
        var state = state
        state.globalSequence &+= 1
        
        switch state.phase {
        case .dealing:
            return .init(state: state, effects: [.invalidIntent(reason: "Not ready, still dealing")])
        case .selecting:
            break
        case .revealing:
            return .init(state: state, effects: [.invalidIntent(reason: "Not ready, revealing")])
        case .matchEnded(let winner):
            return .init(state: state, effects: [.invalidIntent(reason: "Match already ended")])
        }
        
        switch intent {
        case .selectCard(let player, let cardId):
            guard state.config.players.contains(player) else {
                return .init(state: state, effects: [.invalidIntent(reason: "Invalid player")])
            }
            guard state.selections.byPlayer[player] == nil else {
                return .init(state: state, effects: [.invalidIntent(reason: "Player already selected a card this round")])
            }
            guard let card = findCard(inHandOf: player, cardId: cardId, state: state) else {
                return .init(state: state, effects: [.invalidIntent(reason: "Card not in hand")])
            }
            
            guard findCard(inHandOf: player, cardId: cardId, state: state) != nil else {
                return Transition(state: state, effects: [.invalidIntent(reason: "Card not in player's hand")])
            }
            state.selections.byPlayer[player] = cardId
            
            var effects: [Effect] = [
                .cardSelected(player: player, card: cardId),
            ]
            
            if state.selections.isComplete(for: state.config.players) {
                effects.append(contentsOf: resolveRound(&state))
            }
            
            return Transition(state: state, effects: effects)
        case .concede(let player):
            if !state.config.players.contains(player) {
                return .init(state: state, effects: [.invalidIntent(reason: "Invalid player")])
            }
            let winner = state.config.players.first(where: { $0 != player })!
            state.phase = .matchEnded(winner: winner)
            return .init(state: state, effects: [.matchEnded(winner: winner)])
        }
    }
    
    private static func resolveRound(_ state: inout GameState) -> [Effect] {
        state.phase = .revealing
        
        guard state.config.players.count == 2,
              let pA = state.config.players.first,
              let pB = state.config.players.last,
              let cAId = state.selections.byPlayer[pA],
              let cBId = state.selections.byPlayer[pB],
              let cA = findCard(inHandOf: pA, cardId: cAId, state: state),
              let cB = findCard(inHandOf: pB, cardId: cBId, state: state) else {
            
            state.phase = .selecting
            state.selections = .init()
            return [.invalidIntent(reason: "Unsupported player count or missing intentions")]
        }
        
        let outcomeForA = Rules.compare(cA, cB)
        var effects: [Effect] = [
            .revealCards(a: .init(player: pA, card: cA), b: .init(player: pB, card: cB), outcomeForA: outcomeForA)
        ]
        
        removeFromhand(&state, player: pA, cardId: cAId)
        removeFromhand(&state, player: pB, cardId: cBId)
        effects.append(.discard(cards: [cAId, cBId]))
        
        switch outcomeForA {
        case .win:
            awardToken(&state, player: pA, from: cA)
            effects.append(.awardToken(player: pA, award: .init(card: cA, awardedAtSequence: state.globalSequence)))
        case .lose:
            awardToken(&state, player: pB, from: cB)
            effects.append(.awardToken(player: pB, award: .init(card: cB, awardedAtSequence: state.globalSequence)))
        case .draw:
            break
        }
        
        if let dA = drawTopCard(&state, player: pA) { effects.append(.draw(player: pA, card: dA.id)) }
        if let dB = drawTopCard(&state, player: pB) { effects.append(.draw(player: pB, card: dB.id)) }
        
        let winner = state.config.players.first(where: { state.playerZone($0).tokens.isWinning() })
        if let winner {
            state.phase = .matchEnded(winner: winner)
            effects.append(.matchEnded(winner: winner))
            return effects
        }
        
        state.selections = .init()
        state.phase = .selecting
        effects.append(.roundEnded)
        return effects
    }
    
    private static func findCard(inHandOf player: Player, cardId: CardId, state: GameState) -> Card? {
        state.zones[player]?.hand.first(where: { $0.id == cardId })
    }
    
    private static func removeFromhand(_ state: inout GameState, player: Player, cardId: CardId) {
        guard var zone = state.zones[player] else { return }
        guard let idx = zone.hand.firstIndex(where: { $0.id == cardId }) else { return }
        
        let removed = zone.hand.remove(at: idx)
        zone.discard.append(removed)
        state.zones[player] = zone
    }
    
    private static func awardToken(_ state: inout GameState, player: Player, from card: Card) {
        guard var zone = state.zones[player] else { return }
        
        zone.tokens.award(from: card, sequence: state.globalSequence)
        state.zones[player] = zone
    }
    
    private static func drawTopCard(_ state: inout GameState, player: Player) -> Card? {
        guard var zone = state.zones[player] else { return nil }
        guard !zone.deck.isEmpty else { return nil }
        
        let card = zone.deck.removeLast()
        zone.hand.append(card)
        state.zones[player] = zone
        return card
    }
}
