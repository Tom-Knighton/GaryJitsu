//
//  TokenRenderer.swift
//  JitsuGame
//
//  Created by Tom Knighton on 24/02/2026.
//

import SpriteKit
import JitsuCore

/// Owns the per-player token stack nodes and keeps them in sync with `GameState`.
@MainActor
final class TokenRenderer {
    
    let container = SKNode()
    
    private(set) var tokenStackByPlayer: [Player: SKNode] = [:]
    private(set) var elementStacksByPlayer: [Player: [Element: SKNode]] = [:]
    private var lastTokenCounts: [Player: Int] = [:]
    
    // MARK: - Setup
    
    func ensureStacks(players: [Player], local: Player) {
        guard tokenStackByPlayer.isEmpty else { return }
        guard let opp = players.first(where: { $0 != local }) else { return }
        
        let left = SKNode()
        let right = SKNode()
        
        container.addChild(left)
        container.addChild(right)
        
        tokenStackByPlayer[local] = left
        tokenStackByPlayer[opp] = right
        
        for player in [local, opp] {
            guard let parentStack = tokenStackByPlayer[player] else { continue }
            var elementStacks: [Element: SKNode] = [:]
            
            for element in Element.allCases {
                let elementStack = SKNode()
                parentStack.addChild(elementStack)
                elementStacks[element] = elementStack
            }
            
            elementStacksByPlayer[player] = elementStacks
        }
    }
    
    // MARK: - Layout
    
    func positionStacks( players: [Player],
                         local: Player,
                         localPosition: CGPoint,
                         remotePosition: CGPoint) {
        guard let opp = players.first(where: { $0 != local }) else { return }
        guard
            let localStack = tokenStackByPlayer[local],
            let oppStack = tokenStackByPlayer[opp]
        else { return }
        
        localStack.position = localPosition
        oppStack.position = remotePosition
        
        let elementGap: CGFloat = 60
        let elements: [Element] = [.fire, .water, .snow]
        
        for player in [local, opp] {
            guard let elementStacks = elementStacksByPlayer[player] else { continue }
            let isLocal = player == local
            
            for (index, element) in elements.enumerated() {
                guard let elementStack = elementStacks[element] else { continue }
                
                let xOffset = isLocal
                ? CGFloat(index) * elementGap
                : -CGFloat(index) * elementGap
                
                elementStack.position = CGPoint(x: xOffset, y: 0)
            }
        }
    }
    
    // MARK: - Sync from State
    
    func syncFromState(_ state: GameState, players: [Player]) {
        let cardOverlap: CGFloat = -20
        
        for p in players {
            guard let elementStacks = elementStacksByPlayer[p] else { continue }
            let awards = state.playerZone(p).tokens.awards
            
            var awardsByElement: [Element: [TokenAward]] = [:]
            for element in Element.allCases {
                awardsByElement[element] = awards.filter { $0.element == element }
            }
            
            for (element, elementAwards) in awardsByElement {
                guard let elementStack = elementStacks[element] else { continue }
                let existing = Set(elementStack.children.compactMap { ($0 as? TokenNode)?.cardId })
                
                for (i, a) in elementAwards.enumerated() where !existing.contains(a.cardId) {
                    let tokenSize = CGSize(width: 50, height: 50)
                    let tokenColor = colorForElement(a.element)
                    let node = TokenNode(cardId: a.cardId, size: tokenSize, color: tokenColor, element: a.element)
                    node.position = CGPoint(x: 0, y: CGFloat(i) * cardOverlap)
                    node.zPosition = CGFloat(i)
                    elementStack.addChild(node)
                }
            }
        }
    }
}
