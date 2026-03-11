//
//  RevealAnimator.swift
//  JitsuGame
//
//  Created by Tom Knighton on 24/02/2026.
//

import SpriteKit
import JitsuCore

/// Drives the card-reveal animation cycle: flip, compare, optionally award a token.
@MainActor
final class RevealAnimator {
    
    private let handRenderer: HandRenderer
    private let tokenRenderer: TokenRenderer
    private let overlay: SKNode
    private let localPlayer: Player
    
    private var revealingPair: (local: CardNode, opp: CardNode, localId: CardId, oppId: CardId)?
    private(set) var revealInFlight: Bool = false
    
    var onCycleFinished: (() -> Void)?
    
    init(handRenderer: HandRenderer, tokenRenderer: TokenRenderer, overlay: SKNode, localPlayer: Player) {
        self.handRenderer = handRenderer
        self.tokenRenderer = tokenRenderer
        self.overlay = overlay
        self.localPlayer = localPlayer
    }
    
    // MARK: - Entry Point
    
    func startRevealCycle(reveal: Effect, effects: [Effect]) {
        guard let payload = effects.revealPayload else { return }
        let (a, b, _) = payload
        
        let localRevealed = (a.player == localPlayer) ? a : b
        let oppRevealed   = (a.player == localPlayer) ? b : a
        
        let award = effects.firstAwardToken
        
        revealInFlight = true
        
        let localNode = handRenderer.centeredLocalNode(for: localRevealed.card.id, overlay: overlay)
        let oppNode = handRenderer.centeredOpponentNode(for: oppRevealed.card.id, overlay: overlay)
        
        localNode.setFaceUp(true)
        oppNode.setFaceUp(false)
        
        revealingPair = (localNode, oppNode, localRevealed.card.id, oppRevealed.card.id)
        
        localNode.run(.move(to: handRenderer.localCenterTarget(), duration: 0.12))
        oppNode.setCardType(to: .faceDownLarge)
        oppNode.run(.sequence([
            .move(to: handRenderer.opponentCenterTarget(), duration: 0.22),
            flipToFaceUp(oppNode, duration: 0.22),
            .wait(forDuration: 0.25),
            .run { [weak self] in
                self?.completeRevealAwardIfNeeded(award: award)
            }
        ]))
    }
    
    // MARK: - Award / Cleanup
    
    private func completeRevealAwardIfNeeded(award: (player: Player, award: TokenAward)?) {
        guard let pair = revealingPair else {
            finish()
            return
        }
        
        handRenderer.clearCenteredCard(localId: pair.localId, oppId: pair.oppId)
        
        guard let award else {
            let fade = SKAction.fadeOut(withDuration: 0.18)
            pair.local.run(fade)
            pair.opp.run(.sequence([fade, .removeFromParent()])) { [weak self] in
                pair.local.removeFromParent()
                self?.revealingPair = nil
                self?.finish()
            }
            return
        }
        
        let winningNode: CardNode =
        (award.award.cardId == pair.localId) ? pair.local : pair.opp
        let losingNode: CardNode =
        (winningNode === pair.local) ? pair.opp : pair.local
        
        losingNode.run(.sequence([.fadeOut(withDuration: 0.18), .removeFromParent()]))
        
        guard let elementStacks = tokenRenderer.elementStacksByPlayer[award.player],
              let elementStack = elementStacks[award.award.element] else {
            finish()
            return
        }
        
        let cardOverlap: CGFloat = -20
        let idx = elementStack.children.count
        let localPos = CGPoint(x: 0, y: CGFloat(idx) * cardOverlap)
        let target = elementStack.convert(localPos, to: overlay)
        
        let tokenSize = CGSize(width: 50, height: 50)
        let tokenColor = colorForElement(award.award.element)
        let tokenNode = TokenNode(
            cardId: award.award.cardId,
            size: tokenSize,
            color: tokenColor,
            element: award.award.element
        )
        tokenNode.position = winningNode.position
        tokenNode.alpha = 0
        tokenNode.setScale(2.0)
        overlay.addChild(tokenNode)
        
        let cardShrinkFade = SKAction.group([
            .scale(to: 0.3, duration: 0.2),
            .fadeOut(withDuration: 0.2)
        ])
        
        winningNode.run(.sequence([cardShrinkFade, .removeFromParent()]))
        
        tokenNode.run(.sequence([
            .group([
                .fadeIn(withDuration: 0.15),
                .scale(to: 1.0, duration: 0.25),
                .move(to: target, duration: 0.3)
            ]),
            .run { [weak self] in
                guard self != nil else { return }
                tokenNode.removeFromParent()
                tokenNode.position = localPos
                tokenNode.zPosition = CGFloat(idx)
                elementStack.addChild(tokenNode)
                
                self?.revealingPair = nil
                self?.finish()
            }
        ]))
    }
    
    private func finish() {
        revealInFlight = false
        handRenderer.resetCenteredState()
        onCycleFinished?()
    }
    
    // MARK: - Flip Animation
    
    private func flipToFaceUp(_ node: CardNode, duration: TimeInterval) -> SKAction {
        let half = duration / 2
        let originalX = node.xScale
        let shrink = SKAction.scaleX(to: 0.05, duration: half)
        shrink.timingMode = .easeIn
        
        let swap = SKAction.run {
            node.setCardType(to: .faceUpLarge)
        }
        
        let expand = SKAction.scaleX(to: originalX, duration: half)
        expand.timingMode = .easeOut
        
        return .sequence([shrink, swap, expand])
    }
}
