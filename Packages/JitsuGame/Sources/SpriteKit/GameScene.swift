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
    private var pendingEffects: [Effect] = []
    private var lastProcessedRevealSeq: UInt64 = 0
    private var opponentMiniById: [CardId: CardNode] = [:]
    
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
    private var elementStacksByPlayer: [Player: [Element: SKNode]] = [:]
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
        // Local hand on far left
        bottomCards.position = CGPoint(x: w * 0.28, y: trayHeight * 0.52)
        
        // Opponent mini hand on right edge of tray
        opponentMiniCards.position = CGPoint(x: w - 18, y: trayHeight * 0.62)
        
        if let lastPlayers = lastPlayersCache {
            ensureTokenStacks(players: lastPlayers, local: localPlayer)
            positionTokenStacks(players: lastPlayers, local: localPlayer)
        }
    }
    
    public func render(state: GameState, effects: [Effect] = []) {
        if lastRenderedHash == nil {
            apply(state: state)
        }
        
        if isAnimating {
            pendingState = state
            pendingEffects = effects
            return
        }
        
        let hv = state.hashValue
        if lastRenderedHash == hv { return }
        
        if let reveal = effects.firstRevealCards,
           state.globalSequence != lastProcessedRevealSeq {
            lastProcessedRevealSeq = state.globalSequence
            pendingState = state
            pendingEffects = effects
            startRevealCycle(reveal: reveal, effects: effects)
            return
        }
        
        apply(state: state)
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
        opponentMiniById.removeAll()
        
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
            opponentMiniById[id] = node
        }
    }
    
    private func ensureTokenStacks(players: [Player], local: Player) {
        guard tokenStackByPlayer.isEmpty else { return }
        
        guard let opp = players.first(where: { $0 != local }) else { return }
        
        let left = SKNode()
        let right = SKNode()
        
        tokenStacks.addChild(left)
        tokenStacks.addChild(right)
        
        tokenStackByPlayer[local] = left
        tokenStackByPlayer[opp] = right
        
        // Create element sub-stacks for each player
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
    
    private func positionTokenStacks(players: [Player], local: Player) {
        guard let opp = players.first(where: { $0 != local }) else { return }
        guard
            let localStack = tokenStackByPlayer[local],
            let oppStack = tokenStackByPlayer[opp]
        else { return }
        
        let trayHeight = max(140, size.height * 0.22)
        let stackY = trayHeight + (size.height - trayHeight) * 0.75
        
        // Local player tokens on far left
        localStack.position = CGPoint(x: 50, y: stackY)
        // Opponent tokens on far right
        oppStack.position = CGPoint(x: size.width - 50, y: stackY)
        
        // Position element sub-stacks horizontally
        let elementGap: CGFloat = 60  // gap between element stacks
        let elements: [Element] = [.fire, .water, .snow]
        
        for player in [local, opp] {
            guard let elementStacks = elementStacksByPlayer[player] else { continue }
            let isLocal = (player == local)
            
            for (i, element) in elements.enumerated() {
                guard let elementStack = elementStacks[element] else { continue }
                // Local: stacks go left to right (positive x)
                // Opponent: stacks go right to left (negative x) so they stay on screen
                let xOffset = isLocal ? CGFloat(i) * elementGap : -CGFloat(i) * elementGap
                elementStack.position = CGPoint(x: xOffset, y: 0)
            }
        }
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
    
    private func apply(state: GameState) {
        let players = state.config.players
        guard let opponent = players.first(where: { $0 != localPlayer }) else { return }
        
        renderBottomHand(state: state, player: localPlayer)
        renderOpponentHand(state: state, player: opponent)
        renderSelections(state: state, local: localPlayer, opponent: opponent)
        
        lastPlayersCache = players
        ensureTokenStacks(players: players, local: localPlayer)
        positionTokenStacks(players: players, local: localPlayer)
        
        syncTokenStacksFromState(state: state, players: players)
        
        lastRenderedHash = state.hashValue
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
    private func startRevealCycle(reveal: Effect, effects: [Effect]) {
        guard let payload = effects.revealPayload else { return }
        let (a, b, _) = payload
        
        let localRevealed = (a.player == localPlayer) ? a : b
        let oppRevealed   = (a.player == localPlayer) ? b : a
        
        let award = effects.firstAwardToken  // nil on draw
        
        isAnimating = true
        revealInFlight = true
        
        // Clone nodes from current on-screen positions (pre-resolution view)
        let bigSize = CGSize(width: 120, height: 174)
        let localNode = CardNode(cardId: localRevealed.card.id, size: bigSize, faceUp: true)
        let oppNode   = CardNode(cardId: oppRevealed.card.id, size: bigSize, faceUp: false)
        
        let localStart = cardNodesById[localRevealed.card.id]
            .map { $0.parent?.convert($0.position, to: overlay) } ?? bottomCards.convert(.zero, to: overlay)
        
        let oppStart = opponentMiniById[oppRevealed.card.id]
            .map { $0.parent?.convert($0.position, to: overlay) } ?? opponentMiniCards.convert(CGPoint(x: -22, y: 0), to: overlay)
        
        localNode.position = localStart ?? .zero
        oppNode.position = oppStart ?? .zero
        
        overlay.addChild(localNode)
        overlay.addChild(oppNode)
        revealingPair = (localNode, oppNode, localRevealed.card.id, oppRevealed.card.id)
        
        // Move to center and flip opponent
        let centerY = size.height * 0.52
        let centerX = size.width * 0.5
        let spread: CGFloat = 90
        
        let localTarget = CGPoint(x: centerX - spread, y: centerY)
        let oppTarget   = CGPoint(x: centerX + spread, y: centerY)
        
        localNode.run(.move(to: localTarget, duration: 0.22))
        
        oppNode.run(.sequence([
            .move(to: oppTarget, duration: 0.22),
            flipToFaceUp(oppNode, duration: 0.22),
            .wait(forDuration: 0.25),
            .run { [weak self] in self?.completeRevealAwardIfNeeded(award: award) }
        ]))
    }
    
    private func syncTokenStacksFromState(state: GameState, players: [Player]) {
        let cardOverlap: CGFloat = -20  // negative to stack downward with overlap
        
        for p in players {
            guard let elementStacks = elementStacksByPlayer[p] else { continue }
            let awards = state.playerZone(p).tokens.awards
            
            // Group awards by element
            var awardsByElement: [Element: [TokenAward]] = [:]
            for element in Element.allCases {
                awardsByElement[element] = awards.filter { $0.element == element }
            }
            
            for (element, elementAwards) in awardsByElement {
                guard let elementStack = elementStacks[element] else { continue }
                
                // Existing cardIds already in this element stack
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
    
    
    private func completeRevealAwardIfNeeded(award: (player: Player, award: TokenAward)?) {
        guard let pair = revealingPair else { finishAnimationCycle(); return }
        
        // Draw round: fade both out then finish.
        guard let award else {
            let fade = SKAction.fadeOut(withDuration: 0.18)
            pair.local.run(fade)
            pair.opp.run(.sequence([fade, .removeFromParent()])) { [weak self] in
                pair.local.removeFromParent()
                self?.revealingPair = nil
                self?.finishAnimationCycle()
            }
            return
        }
        
        // Determine which card actually won by cardId.
        let winningNode: CardNode =
        (award.award.cardId == pair.localId) ? pair.local : pair.opp
        
        let losingNode: CardNode =
        (winningNode === pair.local) ? pair.opp : pair.local
        
        losingNode.run(.sequence([.fadeOut(withDuration: 0.18), .removeFromParent()]))
        
        // Move winning node onto the correct element stack
        guard let elementStacks = elementStacksByPlayer[award.player],
              let elementStack = elementStacks[award.award.element] else {
            finishAnimationCycle()
            return
        }
        
        let cardOverlap: CGFloat = -20
        let idx = elementStack.children.count
        let localPos = CGPoint(x: 0, y: CGFloat(idx) * cardOverlap)
        let target = elementStack.convert(localPos, to: overlay)
        
        // Create the token node that will replace the card
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
        tokenNode.setScale(2.0)  // Start larger for transition effect
        overlay.addChild(tokenNode)
        
        // Animate: CardNode shrinks and fades out while TokenNode appears and moves to stack
        let cardShrinkFade = SKAction.group([
            .scale(to: 0.3, duration: 0.2),
            .fadeOut(withDuration: 0.2)
        ])
        
        winningNode.run(.sequence([cardShrinkFade, .removeFromParent()]))
        
        // TokenNode fades in, scales down, and moves to target
        tokenNode.run(.sequence([
            .group([
                .fadeIn(withDuration: 0.15),
                .scale(to: 1.0, duration: 0.25),
                .move(to: target, duration: 0.3)
            ]),
            .run { [weak self] in
                guard let self else { return }
                tokenNode.removeFromParent()
                tokenNode.position = localPos
                tokenNode.zPosition = CGFloat(idx)
                elementStack.addChild(tokenNode)
                
                self.revealingPair = nil
                self.finishAnimationCycle()
            }
        ]))
    }
    
    private func colorForElement(_ element: Element) -> UIColor {
        switch element {
        case .fire:  return UIColor(red: 0.9, green: 0.3, blue: 0.2, alpha: 1.0)
        case .water: return UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)
        case .snow:  return UIColor(red: 0.85, green: 0.9, blue: 1.0, alpha: 1.0)
        }
    }
    
    private func finishAnimationCycle() {
        isAnimating = false
        revealInFlight = false
        
        if let next = pendingState {
            pendingState = nil
            pendingEffects = []
            apply(state: next)
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

private extension Array where Element == Effect {
    var firstRevealCards: Effect? {
        first { if case .revealCards = $0 { return true } else { return false } }
    }
    var firstAwardToken: (player: Player, award: TokenAward)? {
        for e in self {
            if case let .awardToken(p, a) = e { return (p, a) }
        }
        return nil
    }
    var revealPayload: (a: RevealedCard, b: RevealedCard, outcomeForA: CardComparisonResult)? {
        for e in self {
            if case let .revealCards(a, b, outcome) = e { return (a, b, outcome) }
        }
        return nil
    }
}
