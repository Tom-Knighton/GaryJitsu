//
//  GameScene.swift
//  JitsuGame
//
//  Created by Tom Knighton on 24/02/2026.
//

import SpriteKit
import JitsuCore

public final class GameScene: SKScene {
    
    public var onSelectCard: ((CardId) -> Void)?
    
    private var localPlayer: Player
    
    private var isAnimating: Bool = false
    private var pendingState: GameState?
    
    private let ui = SKNode()
    private let bg = SKShapeNode()
    
    private var lastPlayersCache: [Player]?
    
    // Arena
    private let arena = SKNode()
    private let leftPlayer = PlayerNode()
    private let rightPlayer = PlayerNode()
    
    // Bottom Tray
    private let bottomTray = SKShapeNode()
    private let bottomCards = SKNode()
    private let opponentMiniCards = SKNode()
    
    private var cardNodesById: [CardId: CardNode] = [:]
    
    // Overlay
    private let overlay = SKNode()
    private let tokenStacks = SKNode()
    private var tokenStackByPlayer: [Player: SKNode] = [:]
    private var lastSelections: [Player: CardId?] = [:]
    private var lastTokenCounts: [Player: Int] = [:]
    
    private var revealingPair: (local: CardNode, opp: CardNode, localId: CardId, oppId: CardId)?
    private var revealInFlight: Bool = false
    
    private var lastRenderedHash: Int?

    public init(localPlayer: Player) {
        self.localPlayer = localPlayer
        super.init(size: .init(width: 390, height: 844))
        scaleMode = .resizeFill
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }
    
    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        backgroundColor = .black
        
        addChild(ui)
        
        // Background
        bg.isAntialiased = true
        bg.strokeColor = .clear
        bg.fillColor = .init(white: 0.12, alpha: 1)
        bg.zPosition = -10
        ui.addChild(bg)
        
        // Arena
        ui.addChild(arena)
        arena.addChild(leftPlayer)
        arena.addChild(rightPlayer)
        
        // Bottom Tray
        bottomTray.isAntialiased = true
        bottomTray.strokeColor = .init(white: 0.25, alpha: 1)
        bottomTray.lineWidth = 2
        bottomTray.fillColor = .init(white: 0.08, alpha: 0.95)
        bottomTray.zPosition = 10
        ui.addChild(bottomTray)
        
        bottomCards.zPosition = 11
        ui.addChild(bottomCards)
        
        // Opponents
        opponentMiniCards.zPosition = 11
        ui.addChild(opponentMiniCards)
        
        leftPlayer.set(color: .yellow, facingRight: true)
        rightPlayer.set(color: .green, facingRight: false)
        
        // Overlay
        ui.addChild(tokenStacks)
        ui.addChild(overlay)
        tokenStacks.zPosition = 50
        overlay.zPosition = 100
    }
    
    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        
        bg.path = CGPath(rect: CGRect(origin: .zero, size: size), transform: nil)
        bg.position = .zero
        
        layoutUI()
    }
    
    private func layoutUI() {
        let w = size.width
        let h = size.height
        
        let trayHeight = max(140, h * 0.22)
        let trayRect = CGRect(x: 0, y: 0, width: w, height: trayHeight)
        bottomTray.path = CGPath(rect: trayRect, transform: nil)
        bottomTray.position = .zero
        
        // Arena sits above tray
        arena.position = CGPoint(x: w * 0.5, y: trayHeight + (h - trayHeight) * 0.45)
        
        leftPlayer.position = CGPoint(x: -w * 0.18, y: 0)
        rightPlayer.position = CGPoint(x: w * 0.18, y: 0)
        
        // --- Bottom tray content ---
        // Local hand left/center
        bottomCards.position = CGPoint(x: w * 0.42, y: trayHeight * 0.52)
        
        // Opponent mini hand on right edge of tray
        opponentMiniCards.position = CGPoint(x: w - 18, y: trayHeight * 0.62)
        
        let players = pendingState?.config.players
        if let lastPlayers = lastPlayersCache {
            ensureTokenStacks(players: lastPlayers, local: localPlayer)
            positionTokenStacks(players: lastPlayers, local: localPlayer)
        }
    }
    
    public func render(state: GameState) {
        if isAnimating {
            pendingState = state
            return
        }
        
        let hv = state.hashValue
        if lastRenderedHash == hv { return }
        lastRenderedHash = hv
        
        let players = state.config.players
        guard let opponent = players.first(where: { $0 != localPlayer }) else { return }
        
        renderBottomHand(state: state, player: localPlayer)
        renderOpponentHand(state: state, player: opponent)
        renderSelections(state: state, local: localPlayer, opponent: opponent)
        lastPlayersCache = state.config.players
        ensureTokenStacks(players: state.config.players, local: localPlayer)
        positionTokenStacks(players: state.config.players, local: localPlayer)
        
        driveAnimations(state: state, local: localPlayer, opponent: opponent)
    }
    private func renderBottomHand(state: GameState, player: Player) {
        let ids = state.handIds(player)
        
        // Remove nodes that no longer exist in hand
        let current = Set(ids)
        for (id, node) in cardNodesById where node.isInBottomTray && !current.contains(id) {
            node.removeFromParent()
            cardNodesById[id] = nil
        }
        
        // Layout 5-slot style
        let slotCount = max(5, ids.count)
        let cardSize = CGSize(width: 76, height: 110)
        let gap: CGFloat = 14
        let totalWidth = CGFloat(slotCount) * cardSize.width + CGFloat(slotCount - 1) * gap
        let startX = -totalWidth / 2 + cardSize.width / 2
        
        for i in 0..<slotCount {
            let x = startX + CGFloat(i) * (cardSize.width + gap)
            let pos = CGPoint(x: x, y: 0)
            
            guard i < ids.count else { continue }
            let id = ids[i]
            
            let node = cardNodesById[id] ?? {
                let n = CardNode(cardId: id, size: cardSize, faceUp: true)
                n.isInBottomTray = true
                cardNodesById[id] = n
                bottomCards.addChild(n)
                return n
            }()
            
            node.setFaceUp(true)
            node.position = pos
        }
    }
    
    private func renderOpponentHand(state: GameState, player: Player) {
        let ids = state.handIds(player)
        
        opponentMiniCards.removeAllChildren()
        
        let cardSize = CGSize(width: 44, height: 64)
        let gap: CGFloat = 8
        
        // Anchor at opponentMiniCards.position (near tray right edge).
        // Place cards leftwards.
        for (i, id) in ids.prefix(5).enumerated() {
            let node = CardNode(cardId: id, size: cardSize, faceUp: false)
            node.isInBottomTray = false
            node.setFaceUp(false)
            
            let x = -CGFloat(i) * (cardSize.width + gap) - cardSize.width / 2
            let y: CGFloat = 0
            node.position = CGPoint(x: x, y: y)
            opponentMiniCards.addChild(node)
        }
    }
    
    private func ensureTokenStacks(players: [Player], local: Player) {
        guard tokenStackByPlayer.isEmpty else { return }
        
        guard let opp = players.first(where: { $0 != local }) else { return }
        
        let left = SKNode()
        let right = SKNode()
        
        tokenStacks.addChild(left)
        tokenStacks.addChild(right)
        
        tokenStackByPlayer[local] = right
        tokenStackByPlayer[opp] = left
    }
    
    private func positionTokenStacks(players: [Player], local: Player) {
        guard let opp = players.first(where: { $0 != local }) else { return }
        guard
            let localStack = tokenStackByPlayer[local],
            let oppStack = tokenStackByPlayer[opp]
        else { return }
        
        oppStack.position = arena.convert(
            CGPoint(x: leftPlayer.position.x, y: leftPlayer.position.y + 120),
            to: ui
        )
        localStack.position = arena.convert(
            CGPoint(x: rightPlayer.position.x, y: rightPlayer.position.y + 120),
            to: ui
        )
    }
    
    private func renderSelections(state: GameState, local: Player, opponent: Player) {
        let localSelected = state.selectedCardId(local)
        let oppSelected = state.selectedCardId(opponent)
        
        for (id, node) in cardNodesById {
            node.setSelected(id == localSelected)
        }
        
        leftPlayer.setReady(localSelected != nil)
        rightPlayer.setReady(oppSelected != nil)
    }
   
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let p = touch.location(in: self)
        
        let hit = atPoint(p)
        
        if let card = hit.closestAncestor(of: CardNode.self), card.isInBottomTray {
            onSelectCard?(card.cardId)
        }
    }
}


// MARK: Animations
extension GameScene {
    private func driveAnimations(state: GameState, local: Player, opponent: Player) {
        if lastTokenCounts.isEmpty {
            lastTokenCounts[local] = state.tokenCount(local)
            lastTokenCounts[opponent] = state.tokenCount(opponent)
        }
        
        let localSel = state.selectedCardId(local)
        let oppSel = state.selectedCardId(opponent)
        
        let prevLocalSel = lastSelections[local] ?? nil
        let prevOppSel = lastSelections[opponent] ?? nil
        
        let prevBoth = (prevLocalSel != nil) && (prevOppSel != nil)
        let nowBoth = (localSel != nil) && (oppSel != nil)
        
        if !prevBoth, nowBoth, let l = localSel, let o = oppSel {
            startRevealAnimation(local: local, opponent: opponent, localCard: l, oppCard: o)
        }
        
        let prevLocalTokens = lastTokenCounts[local] ?? 0
        let prevOppTokens = lastTokenCounts[opponent] ?? 0
        let nowLocalTokens = state.tokenCount(local)
        let nowOppTokens = state.tokenCount(opponent)
        
        if nowLocalTokens > prevLocalTokens {
            awardToken(to: local, state: state, local: local, opponent: opponent)
        } else if nowOppTokens > prevOppTokens {
            awardToken(to: opponent, state: state, local: local, opponent: opponent)
        }
        
        lastSelections[local] = localSel
        lastSelections[opponent] = oppSel
        lastTokenCounts[local] = nowLocalTokens
        lastTokenCounts[opponent] = nowOppTokens
    }
    
    private func startRevealAnimation(local: Player, opponent: Player, localCard: CardId, oppCard: CardId) {
        guard !revealInFlight else { return }
        revealInFlight = true
        isAnimating = true
        
        let bigSize = CGSize(width: 120, height: 174)
        
        let localNode = CardNode(cardId: localCard, size: bigSize, faceUp: true)
        let oppNode = CardNode(cardId: oppCard, size: bigSize, faceUp: false)
        
        let localStart: CGPoint = {
            if let trayNode = cardNodesById[localCard] {
                return trayNode.parent?.convert(trayNode.position, to: overlay)
                ?? bottomCards.convert(.zero, to: overlay)
            }
            return bottomCards.convert(.zero, to: overlay)
        }()
        let oppStart = opponentMiniCards.convert(CGPoint(x: -22, y: 0), to: overlay)
        
        localNode.position = localStart
        oppNode.position = oppStart
        
        overlay.addChild(localNode)
        overlay.addChild(oppNode)
        
        revealingPair = (localNode, oppNode, localCard, oppCard)
        
        let centerY = size.height * 0.52
        let centerX = size.width * 0.5
        let spread: CGFloat = 90
        
        let localTarget = CGPoint(x: centerX - spread, y: centerY)
        let oppTarget = CGPoint(x: centerX + spread, y: centerY)
        
        let moveLocal = SKAction.move(to: localTarget, duration: 0.22)
        moveLocal.timingMode = .easeOut
        
        let moveOpp = SKAction.move(to: oppTarget, duration: 0.22)
        moveOpp.timingMode = .easeOut
        
        localNode.run(moveLocal)
        oppNode.run(.sequence([
            moveOpp,
            flipToFaceUp(oppNode, duration: 0.22),
        ])) { [weak self] in
            guard let self else { return }
            self.revealInFlight = false
            self.finishAnimationCycle()
        }
    }
    
    private func flipToFaceUp(_ node: CardNode, duration: TimeInterval) -> SKAction {
        let half = duration / 2
        let shrink = SKAction.scaleX(to: 0.05, duration: half)
        shrink.timingMode = .easeIn
        
        let swap = SKAction.run { node.setFaceUp(true) }
        
        let expand = SKAction.scaleX(to: 1.0, duration: half)
        expand.timingMode = .easeOut
        
        return .sequence([shrink, swap, expand])
    }
    
    private func finishAnimationCycle() {
        isAnimating = false
        if let next = pendingState {
            pendingState = nil
            render(state: next)
        }
    }
}


// MARK: Award Token
extension GameScene {
    private func awardToken(to winner: Player, state: GameState, local: Player, opponent: Player) {
        guard let pair = revealingPair else { return }
        guard let stack = tokenStackByPlayer[winner] else { return }
        
        isAnimating = true
        
        let tokenNode: CardNode = (winner == local) ? pair.local : pair.opp
        
        let existing = stack.children.count
        let offsetY = CGFloat(existing) * 8
        let offsetX = CGFloat(existing) * 10
        
        let target = stack.convert(CGPoint(x: offsetX, y: offsetY), to: overlay)
        
        tokenNode.removeAllActions()
        tokenNode.run(.group([
            .move(to: target, duration: 0.25),
            .scale(to: 0.55, duration: 0.25),
        ])) { [weak self] in
            guard let self else { return }
            
            let finalPos = self.overlay.convert(target, to: stack)
            tokenNode.removeFromParent()
            tokenNode.position = finalPos
            stack.addChild(tokenNode)
            
            if pair.local !== tokenNode { pair.local.removeFromParent() }
            if pair.opp !== tokenNode { pair.opp.removeFromParent() }
            
            self.revealingPair = nil
            self.finishAnimationCycle()
        }
    }
}

private extension SKNode {
    func closestAncestor<T: SKNode>(of _: T.Type) -> T? {
        var n: SKNode? = self
        while let current = n {
            if let t = current as? T { return t }
            n = current.parent
        }
        return nil
    }
}
