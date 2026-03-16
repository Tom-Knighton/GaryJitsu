//
//  IntroAnimator.swift
//  JitsuGame
//
//  Created by Tom Knighton on 24/02/2026.
//

import SpriteKit

@MainActor
final class IntroAnimator {
    
    struct Layout: Equatable {
        let sceneBounds: CGRect
        let arenaPosition: CGPoint
        let leftFinalPosition: CGPoint
        let rightFinalPosition: CGPoint
    }
    
    private let leftPlayer: PlayerNode
    private let rightPlayer: PlayerNode
    private let bottomCards: SKNode
    private let opponentMiniCards: SKNode
    
    private(set) var introCompleted = false
    private var introAnimating = false
    private var introRequested = false
    
    var onIntroComplete: (() -> Void)?
    var offscreenPadding: CGFloat = 120
    
    private var layout: Layout?
    
    init(
        leftPlayer: PlayerNode,
        rightPlayer: PlayerNode,
        bottomCards: SKNode,
        opponentMiniCards: SKNode
    ) {
        self.leftPlayer = leftPlayer
        self.rightPlayer = rightPlayer
        self.bottomCards = bottomCards
        self.opponentMiniCards = opponentMiniCards
    }
    
    var hasStartedOrCompleted: Bool {
        introRequested || introAnimating || introCompleted
    }
    
    func updateLayout(
        sceneBounds: CGRect,
        arenaPosition: CGPoint,
        leftFinalPosition: CGPoint,
        rightFinalPosition: CGPoint
    ) {
        guard !sceneBounds.isEmpty else { return }
        
        layout = Layout(
            sceneBounds: sceneBounds,
            arenaPosition: arenaPosition,
            leftFinalPosition: leftFinalPosition,
            rightFinalPosition: rightFinalPosition
        )
        
        tryBeginIfPossible()
    }
    
    func beginIfNeeded() {
        introRequested = true
        tryBeginIfPossible()
    }
    
    private func tryBeginIfPossible() {
        guard introRequested, !introCompleted, !introAnimating else { return }
        guard let layout else { return }
        
        introAnimating = true
        
        bottomCards.alpha = 0
        opponentMiniCards.alpha = 0
        
        leftPlayer.removeAllActions()
        rightPlayer.removeAllActions()
        
        leftPlayer.play(.walk)
        rightPlayer.play(.walk)
        
        let leftStartX = layout.sceneBounds.minX - layout.arenaPosition.x - offscreenPadding
        let rightStartX = layout.sceneBounds.maxX - layout.arenaPosition.x + offscreenPadding
        
        leftPlayer.position = CGPoint(x: leftStartX, y: layout.leftFinalPosition.y)
        rightPlayer.position = CGPoint(x: rightStartX, y: layout.rightFinalPosition.y)
        
        let leftWalk = SKAction.move(to: layout.leftFinalPosition, duration: 0.0)
        let rightWalk = SKAction.move(to: layout.rightFinalPosition, duration: 0.0)
        leftWalk.timingMode = .easeOut
        rightWalk.timingMode = .easeOut
        
        leftPlayer.run(leftWalk)
        rightPlayer.run(.sequence([
            rightWalk,
            .run { [weak self] in
                guard let self else { return }
                self.leftPlayer.play(.idleReady)
                self.rightPlayer.play(.idleReady)
            },
            .wait(forDuration: 1),
            .run { [weak self] in
                self?.flutterCardsIntoView()
            }
        ]))
    }
    
    private func flutterCardsIntoView() {
        let nodes = bottomCards.children + opponentMiniCards.children
        
        bottomCards.alpha = 1
        opponentMiniCards.alpha = 1
        
        for node in nodes {
            let target = node.position
            node.position = CGPoint(x: target.x, y: target.y + 34)
            node.alpha = 0
            node.zRotation = 0.08
            
            node.run(.group([
                .move(to: target, duration: 0.24),
                .fadeIn(withDuration: 0.2),
                .rotate(toAngle: 0, duration: 0.24)
            ]))
        }
        
        introCompleted = true
        introAnimating = false
        onIntroComplete?()
    }
}
