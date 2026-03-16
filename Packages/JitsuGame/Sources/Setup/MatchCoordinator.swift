//
//  MatchCoordinator.swift
//  JitsuGame
//
//  Created by Tom Knighton on 24/02/2026.
//

import Foundation
import JitsuCore
import JitsuMatch

@MainActor
@Observable
public final class MatchCoordinator {
    public let localPlayer: Player
    public let matchData: MatchData
    public let session: Session
    public var autoOpponent: Bool = true
    
    @MainActor
    private var autoTask: Task<Void, Never>?

    public var state: GameState { session.state }
    public var effects: [Effect] { session.lastEffects }
    
    public init(localPlayer: Player, matchData: MatchData, session: Session) {
        self.localPlayer = localPlayer
        self.session = session
        self.matchData = matchData
    }
    
    func start() {
        session.start()
    }
    
    func stop() {
        session.stop()
    }
    
    func selectCard(_ cardId: CardId) {
        session.submit(.selectCard(player: localPlayer, card: cardId))
        
        guard autoOpponent else { return }
        
        autoTask?.cancel()
        autoTask = Task { [weak self] in
            guard let self else { return }
            
            try? await Task.sleep(nanoseconds: 350_000_000)
            
            let players = self.state.config.players
            guard let opponent = players.first(where: { $0 != self.localPlayer }) else { return }
            guard self.state.selectedCardId(opponent) == nil else { return }
            guard let oppCard = self.state.handIds(opponent).first else { return }
            
            self.session.submit(.selectCard(player: opponent, card: oppCard))
        }
    }
    
    
    func concede() {
        session.submit(.concede(player: localPlayer))
    }
}
