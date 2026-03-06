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
    
    private var lastUpdateTime: TimeInterval = 0
    
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
    private var localSlotByCardId: [CardId: Int] = [:]
    private var opponentSlotByCardId: [CardId: Int] = [:]
    private var localReservedSlot: Int?
    private var opponentReservedSlot: Int?
    private var centeredLocalCardId: CardId?
    private var centeredOpponentCardId: CardId?
    
    // Overlay
    private let overlay = SKNode()
    private let tokenStacks = SKNode()
    private var tokenStackByPlayer: [Player: SKNode] = [:]
    private var elementStacksByPlayer: [Player: [Element: SKNode]] = [:]
    private var lastSelections: [Player: CardId?] = [:]
    private var lastTokenCounts: [Player: Int] = [:]
    
    private var revealingPair: (local: CardNode, opp: CardNode, localId: CardId, oppId: CardId)?
    private var revealInFlight: Bool = false
    private var introCompleted: Bool = false
    private var introAnimating: Bool = false
    private var dealingCards: Set<CardId> = []
    
    private var lastRenderedHash: Int?
    
    private let localSlotCount = 5
    private let localCardSize = CGSize(width: 76, height: 110)
    private let localCardGap: CGFloat = 14
    private let opponentCardSize = CGSize(width: 44, height: 64)
    private let opponentCardGap: CGFloat = 8
    
    public init(localPlayer: Player) {
        self.localPlayer = localPlayer
        super.init(size: .init(width: 390, height: 844))
        scaleMode = .resizeFill
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }
    
    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        Task { @MainActor in
            await leftPlayer.preload(anims: [.idleReady, .walk])
            await rightPlayer.preload(anims: [.idleReady, .walk])
        }
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
    
    public override func update(_ currentTime: TimeInterval) {
        let dt: TimeInterval
        if lastUpdateTime == 0 {
            dt = 1.0 / 60.0
        } else {
            dt = currentTime - lastUpdateTime
        }
        lastUpdateTime = currentTime
        
        leftPlayer.update(dt: dt)
        rightPlayer.update(dt: dt)
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
        let arenaPaddingAboveTray: CGFloat = 10
        arena.position = CGPoint(x: w * 0.5, y: trayHeight + arenaPaddingAboveTray)
        
        // Horizontal spacing for fighters around center
        leftPlayer.position = CGPoint(x: -w * 0.75, y: 10)
        rightPlayer.position = CGPoint(x:  w * 0.75, y: arenaPaddingAboveTray)
        
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
            beginIntroIfNeeded()
        }
        
        if isAnimating || !dealingCards.isEmpty {
            pendingState = state
            pendingEffects = effects
            return
        }
        
        let hv = state.hashValue
        if lastRenderedHash == hv {
            return
        }
        
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
        rebuildSlots(ids: ids, slotByCard: &localSlotByCardId, reservedSlot: &localReservedSlot, centeredCardId: centeredLocalCardId, slotCount: localSlotCount)
        
        let current = Set(ids)
        for (id, node) in cardNodesById where node.isInBottomTray && !current.contains(id) && id != centeredLocalCardId {
            node.removeFromParent()
            cardNodesById[id] = nil
        }
        
        let totalWidth = CGFloat(localSlotCount) * localCardSize.width + CGFloat(localSlotCount - 1) * localCardGap
        let startX = -totalWidth / 2 + localCardSize.width / 2
        let slotToId = Dictionary(uniqueKeysWithValues: localSlotByCardId.map { ($1, $0) })
        
        for i in 0..<localSlotCount {
            guard let id = slotToId[i], id != centeredLocalCardId else { continue }
            
            let x = startX + CGFloat(i) * (localCardSize.width + localCardGap)
            let pos = CGPoint(x: x, y: 0)
            
            let existingNode = cardNodesById[id]
            let isNewNode = existingNode == nil
            let node = existingNode ?? {
                let n = CardNode(cardId: id, size: localCardSize, faceUp: true)
                n.isInBottomTray = true
                cardNodesById[id] = n
                return n
            }()
                        
            if localReservedSlot == i && !dealingCards.contains(id) {
                let spawn = bottomCards.convert(CGPoint(x: size.width * 0.55, y: 0), from: self)
                node.position = spawn
                node.alpha = 0
                
                if node.parent == nil {
                    bottomCards.addChild(node)
                }
                
                dealingCards.insert(id)
                
                let animation = SKAction.group([.move(to: pos, duration: 0.25), .fadeIn(withDuration: 0.2)])
                let cardId = id
                let sequence = SKAction.sequence([
                    animation,
                    .run { [weak self] in
                        guard let self else { return }
                        self.dealingCards.remove(cardId)
                        if self.dealingCards.isEmpty, let next = self.pendingState {
                            self.pendingState = nil
                            self.pendingEffects = []
                            self.apply(state: next)
                        }
                    }
                ])
                node.run(sequence, withKey: "dealing")
                
                localReservedSlot = nil
            } else if dealingCards.contains(id) {
                print("DEBUG renderLoop: BRANCH=SKIP_DEALING for \(id.rawValue)")
            } else {
                if node.parent == nil {
                    bottomCards.addChild(node)
                }
                
                if isNewNode || node.position == .zero {
                    node.position = pos
                } else if node.position != pos {
                    node.run(.move(to: pos, duration: 0.1))
                }
            }
        }
    }
    
    private func renderOpponentHand(state: GameState, player: Player) {
        let ids = state.handIds(player)
        rebuildSlots(ids: ids, slotByCard: &opponentSlotByCardId, reservedSlot: &opponentReservedSlot, centeredCardId: centeredOpponentCardId, slotCount: localSlotCount)
        
        let current = Set(ids)
        for (id, node) in opponentMiniById where !node.isInBottomTray && !current.contains(id) && id != centeredOpponentCardId {
            node.removeFromParent()
            opponentMiniById[id] = nil
        }
        
        let totalWidth = CGFloat(localSlotCount) * opponentCardSize.width + CGFloat(localSlotCount - 1) * opponentCardGap
        let startX = -totalWidth / 2 + opponentCardSize.width / 2
        let slotToId = Dictionary(uniqueKeysWithValues: opponentSlotByCardId.map { ($1, $0) })
        
        for i in 0..<localSlotCount {
            guard let id = slotToId[i], id != centeredOpponentCardId else { continue }
            
            let x = startX - CGFloat(i) * (opponentCardSize.width + opponentCardGap)
            let pos = CGPoint(x: x, y: 0)
            
            let node = opponentMiniById[id] ?? {
                let n = CardNode(cardId: id, size: opponentCardSize, faceUp: false)
                n.isInBottomTray = false
                opponentMiniById[id] = n
                opponentMiniCards.addChild(n)
                return n
            }()
            if node.parent == nil { opponentMiniCards.addChild(node) }
            
            if opponentReservedSlot == i {
                let spawn = opponentMiniCards.convert(CGPoint(x: size.width * 0.55, y: size.height + 1.7), from: self)
                node.position = spawn
                node.alpha = 0
                node.run(.group([.move(to: pos, duration: 1.25), .fadeIn(withDuration: 0.2)]))
                opponentReservedSlot = nil
            } else if node.position == .zero {
                node.position = pos
            } else {
                node.run(.move(to: pos, duration: 0.1))
            }
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
        let stackY = trayHeight + (size.height - trayHeight) * 0.90
        
        localStack.position = CGPoint(x: -50, y: stackY)
        oppStack.position = CGPoint(x: size.width + 50, y: stackY)
        
        let elementGap: CGFloat = 60  // gap between element stacks
        let elements: [Element] = [.fire, .water, .snow]
        
        for player in [local, opp] {
            guard let elementStacks = elementStacksByPlayer[player] else { continue }
            let isLocal = (player == local)
            
            for (i, element) in elements.enumerated() {
                guard let elementStack = elementStacks[element] else { continue }
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
        
        if let localSelected { moveLocalSelectionToCenter(cardId: localSelected) }
        if let oppSelected { moveOpponentSelectionToCenter(cardId: oppSelected) }
        
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
    
    private func rebuildSlots(ids: [CardId], slotByCard: inout [CardId: Int], reservedSlot: inout Int?, centeredCardId: CardId?, slotCount: Int) {
        let idSet = Set(ids)
        slotByCard = slotByCard.filter { idSet.contains($0.key) || $0.key == centeredCardId }
                
        let occupied = Set(slotByCard.values)
        var available = Array((0..<slotCount).filter { !occupied.contains($0) })
        
        
        for id in ids where slotByCard[id] == nil {
            if let reserved = reservedSlot, available.contains(reserved) {
                slotByCard[id] = reserved
                available.removeAll(where: { $0 == reserved })
            } else if let first = available.first {
                slotByCard[id] = first
                available.removeFirst()
            }
        }
    }
    
    private func beginIntroIfNeeded() {
        guard !introCompleted, !introAnimating else { return }
        introAnimating = true
        
        bottomCards.alpha = 0
        opponentMiniCards.alpha = 0
        
        let leftFinal = leftPlayer.position
        let rightFinal = rightPlayer.position
        
        leftPlayer.play(.walk)
        rightPlayer.play(.walk)
        leftPlayer.position = CGPoint(x: -size.width * 0.65, y: leftFinal.y)
        rightPlayer.position = CGPoint(x: size.width * 0.65, y: rightFinal.y)
        
        let leftWalk = SKAction.move(to: leftFinal, duration: 5)
        let rightWalk = SKAction.move(to: rightFinal, duration: 5)
        leftWalk.timingMode = .easeOut
        rightWalk.timingMode = .easeOut
        
        leftPlayer.run(leftWalk)
        rightPlayer.run(.sequence([
            rightWalk,
            .run { [weak self] in
                self?.leftPlayer.play(.idleReady)
                self?.rightPlayer.play(.idleReady)
            },
            .wait(forDuration: 1.0),
            .run { [weak self] in self?.flutterCardsIntoView() }
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
    }
    
    private func moveLocalSelectionToCenter(cardId: CardId) {
        guard centeredLocalCardId != cardId, let node = cardNodesById[cardId] else { return }
        centeredLocalCardId = cardId
        localReservedSlot = localSlotByCardId[cardId]
        
        let start = node.parent?.convert(node.position, to: overlay) ?? bottomCards.convert(.zero, to: overlay)
        node.removeFromParent()
        overlay.addChild(node)
        node.position = start
        node.zPosition = 200
        node.run(.move(to: localCenterTarget(), duration: 0.2))
    }
    
    private func moveOpponentSelectionToCenter(cardId: CardId) {
        guard centeredOpponentCardId != cardId, let node = opponentMiniById[cardId] else { return }
        centeredOpponentCardId = cardId
        opponentReservedSlot = opponentSlotByCardId[cardId]
        
        let start = node.parent?.convert(node.position, to: overlay) ?? opponentMiniCards.convert(CGPoint(x: -22, y: 0), to: overlay)
        node.removeFromParent()
        overlay.addChild(node)
        node.position = start
        node.zPosition = 200
        node.run(.move(to: opponentCenterTarget(), duration: 0.2))
    }
    
    private func localCenterTarget() -> CGPoint {
        CGPoint(x: size.width * 0.5 - 90, y: size.height * 0.52)
    }
    
    private func opponentCenterTarget() -> CGPoint {
        CGPoint(x: size.width * 0.5 + 90, y: size.height * 0.52)
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
        guard let payload = effects.revealPayload else {
            return
        }
        let (a, b, _) = payload
        
        let localRevealed = (a.player == localPlayer) ? a : b
        let oppRevealed   = (a.player == localPlayer) ? b : a
        
        let award = effects.firstAwardToken
                
        isAnimating = true
        revealInFlight = true
        
        let localNode = centeredLocalNode(for: localRevealed.card.id)
        let oppNode = centeredOpponentNode(for: oppRevealed.card.id)
        
        localNode.setFaceUp(true)
        oppNode.setFaceUp(false)
        
        revealingPair = (localNode, oppNode, localRevealed.card.id, oppRevealed.card.id)
                
        localNode.run(.move(to: localCenterTarget(), duration: 0.12))
        oppNode.run(.sequence([
            .move(to: opponentCenterTarget(), duration: 0.22),
            flipToFaceUp(oppNode, duration: 0.22),
            .wait(forDuration: 0.25),
            .run { [weak self] in
                self?.completeRevealAwardIfNeeded(award: award)
            }
        ]))
    }
    
    private func centeredLocalNode(for id: CardId) -> CardNode {
        if let node = cardNodesById[id] {
            if node.parent !== overlay {
                let start = node.parent?.convert(node.position, to: overlay) ?? bottomCards.convert(.zero, to: overlay)
                node.removeFromParent()
                overlay.addChild(node)
                node.position = start
            }
            return node
        }
        
        let node = CardNode(cardId: id, size: localCardSize, faceUp: true)
        node.position = localCenterTarget()
        overlay.addChild(node)
        cardNodesById[id] = node
        return node
    }
    
    private func centeredOpponentNode(for id: CardId) -> CardNode {
        if let node = opponentMiniById[id] {
            if node.parent !== overlay {
                let start = node.parent?.convert(node.position, to: overlay) ?? opponentMiniCards.convert(CGPoint(x: -22, y: 0), to: overlay)
                node.removeFromParent()
                overlay.addChild(node)
                node.position = start
            }
            return node
        }
        
        let node = CardNode(cardId: id, size: opponentCardSize, faceUp: false)
        node.position = opponentCenterTarget()
        overlay.addChild(node)
        opponentMiniById[id] = node
        return node
    }
    
    private func syncTokenStacksFromState(state: GameState, players: [Player]) {
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
    
    
    private func completeRevealAwardIfNeeded(award: (player: Player, award: TokenAward)?) {
        guard let pair = revealingPair else {
            finishAnimationCycle()
            return
        }
        
        cardNodesById[pair.localId] = nil
        opponentMiniById[pair.oppId] = nil
        
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
        
        let winningNode: CardNode =
        (award.award.cardId == pair.localId) ? pair.local : pair.opp
        
        let losingNode: CardNode =
        (winningNode === pair.local) ? pair.opp : pair.local
        
        losingNode.run(.sequence([.fadeOut(withDuration: 0.18), .removeFromParent()]))
        
        guard let elementStacks = elementStacksByPlayer[award.player],
              let elementStack = elementStacks[award.award.element] else {
            finishAnimationCycle()
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
        centeredLocalCardId = nil
        centeredOpponentCardId = nil
        
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
