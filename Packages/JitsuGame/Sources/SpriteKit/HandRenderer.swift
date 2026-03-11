//
//  HandRenderer.swift
//  JitsuGame
//
//  Created by Tom Knighton on 24/02/2026.
//

import SpriteKit
import JitsuCore
import JitsuMatch

/// Owns card-slot management, card node caches, and rendering for both local and opponent hands.
@MainActor
final class HandRenderer {
    
    // MARK: - Configuration
    
    let slotCount = 5
    let localCardSize = CGSize(width: 76, height: 110)
    let localCardGap: CGFloat = 14
    let opponentCardSize = CGSize(width: 44, height: 64)
    let opponentCardGap: CGFloat = 8
    
    // MARK: - Container Nodes (owned, added to scene by GameScene)
    
    let bottomCards = SKNode()
    let opponentMiniCards = SKNode()
    
    // MARK: - Node Caches
    
    private(set) var cardNodesById: [CardId: CardNode] = [:]
    private(set) var opponentMiniById: [CardId: CardNode] = [:]
    
    // MARK: - Slot State
    
    private var localSlotByCardId: [CardId: Int] = [:]
    private var opponentSlotByCardId: [CardId: Int] = [:]
    var localReservedSlot: Int?
    var opponentReservedSlot: Int?
    var centeredLocalCardId: CardId?
    var centeredOpponentCardId: CardId?
    private(set) var dealingCards: Set<CardId> = []
    
    // MARK: - Callbacks
    
    /// Called when all dealing animations finish and there's a pending state to flush.
    var onDealingComplete: ((GameState) -> Void)?
    
    // MARK: - Scene geometry (updated by GameScene on layout)
    
    weak var sceneNode: SKScene?
    var logicalFrame: CGRect = .zero
    
    // MARK: - Local Hand
    
    func renderBottomHand(state: GameState, player: Player) {
        let ids = state.handIds(player)
        rebuildSlots(ids: ids, slotByCard: &localSlotByCardId, reservedSlot: &localReservedSlot, centeredCardId: centeredLocalCardId, slotCount: slotCount)
        
        let current = Set(ids)
        for (id, node) in cardNodesById where node.isInBottomTray && !current.contains(id) && id != centeredLocalCardId {
            node.removeFromParent()
            cardNodesById[id] = nil
        }
        
        let totalWidth = CGFloat(slotCount) * localCardSize.width + CGFloat(slotCount - 1) * localCardGap
        let startX = -totalWidth / 2 + localCardSize.width / 2
        let slotToId = Dictionary(uniqueKeysWithValues: localSlotByCardId.map { ($1, $0) })
        
        for i in 0..<slotCount {
            guard let id = slotToId[i], id != centeredLocalCardId else { continue }
            
            let x = startX + CGFloat(i) * (localCardSize.width + localCardGap)
            let pos = CGPoint(x: x, y: 0)
            
            let existingNode = cardNodesById[id]
            let isNewNode = existingNode == nil
            let node = existingNode ?? {
                let n = CardNode(cardId: id, cardType: .faceUpLarge)
                n.isInBottomTray = true
                cardNodesById[id] = n
                return n
            }()
            
            if localReservedSlot == i && !dealingCards.contains(id) {
                let scenePoint = CGPoint(x: logicalFrame.width * 0.55, y: 0)
                let spawn: CGPoint
                if let scene = sceneNode {
                    spawn = bottomCards.convert(scenePoint, from: scene)
                } else {
                    spawn = scenePoint
                }
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
                        if self.dealingCards.isEmpty {
                            self.onDealingComplete?(state)
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
    
    // MARK: - Opponent Hand
    
    func renderOpponentHand(state: GameState, player: Player) {
        let ids = state.handIds(player)
        rebuildSlots(ids: ids, slotByCard: &opponentSlotByCardId, reservedSlot: &opponentReservedSlot, centeredCardId: centeredOpponentCardId, slotCount: slotCount)
        
        let current = Set(ids)
        for (id, node) in opponentMiniById where !node.isInBottomTray && !current.contains(id) && id != centeredOpponentCardId {
            node.removeFromParent()
            opponentMiniById[id] = nil
        }
        
        let totalWidth = CGFloat(slotCount) * opponentCardSize.width + CGFloat(slotCount - 1) * opponentCardGap
        let startX = -totalWidth / 2 + opponentCardSize.width / 2
        let slotToId = Dictionary(uniqueKeysWithValues: opponentSlotByCardId.map { ($1, $0) })
        
        for i in 0..<slotCount {
            guard let id = slotToId[i], id != centeredOpponentCardId else { continue }
            
            let x = startX - CGFloat(i) * (opponentCardSize.width + opponentCardGap)
            let pos = CGPoint(x: x, y: 0)
            
            let node = opponentMiniById[id] ?? {
                let n = CardNode(cardId: id, cardType: .faceDownSmall)
                n.isInBottomTray = false
                opponentMiniById[id] = n
                opponentMiniCards.addChild(n)
                return n
            }()
            if node.parent == nil { opponentMiniCards.addChild(node) }
            
            if opponentReservedSlot == i {
                let scenePoint = CGPoint(x: logicalFrame.width * 0.55, y: logicalFrame.height + 1.7)
                let spawn: CGPoint
                if let scene = sceneNode {
                    spawn = opponentMiniCards.convert(scenePoint, from: scene)
                } else {
                    spawn = scenePoint
                }
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
    
    // MARK: - Selections
    
    func renderSelections(state: GameState, local: Player, opponent: Player, overlay: SKNode, leftPlayer: PlayerNode, rightPlayer: PlayerNode) {
        let localSelected = state.selectedCardId(local)
        let oppSelected = state.selectedCardId(opponent)
        
        for (id, node) in cardNodesById {
            node.setSelected(id == localSelected)
        }
        
        if let localSelected {
            moveLocalSelectionToCenter(cardId: localSelected, overlay: overlay)
        }
        if let oppSelected {
            moveOpponentSelectionToCenter(cardId: oppSelected, overlay: overlay)
        }
        
        leftPlayer.setReady(localSelected != nil)
        rightPlayer.setReady(oppSelected != nil)
    }
    
    // MARK: - Center Cards for Reveal
    
    func moveLocalSelectionToCenter(cardId: CardId, overlay: SKNode) {
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
    
    func moveOpponentSelectionToCenter(cardId: CardId, overlay: SKNode) {
        guard centeredOpponentCardId != cardId, let node = opponentMiniById[cardId] else { return }
        centeredOpponentCardId = cardId
        opponentReservedSlot = opponentSlotByCardId[cardId]
        
        let start = node.parent?.convert(node.position, to: overlay) ?? opponentMiniCards.convert(CGPoint(x: -22, y: 0), to: overlay)
        node.removeFromParent()
        overlay.addChild(node)
        node.position = start
        node.zPosition = 200
        node.run(.scale(by: localCardSize.width / opponentCardSize.width, duration: 0.2))
        node.run(.move(to: opponentCenterTarget(), duration: 0.2))
    }
    
    func centeredLocalNode(for id: CardId, overlay: SKNode) -> CardNode {
        if let node = cardNodesById[id] {
            if node.parent !== overlay {
                let start = node.parent?.convert(node.position, to: overlay) ?? bottomCards.convert(.zero, to: overlay)
                node.removeFromParent()
                overlay.addChild(node)
                node.position = start
            }
            return node
        }
        
        let node = CardNode(cardId: id, cardType: .faceUpLarge)
        node.position = localCenterTarget()
        overlay.addChild(node)
        cardNodesById[id] = node
        return node
    }
    
    func centeredOpponentNode(for id: CardId, overlay: SKNode) -> CardNode {
        if let node = opponentMiniById[id] {
            if node.parent !== overlay {
                let start = node.parent?.convert(node.position, to: overlay) ?? opponentMiniCards.convert(CGPoint(x: -22, y: 0), to: overlay)
                node.removeFromParent()
                overlay.addChild(node)
                node.position = start
            }
            return node
        }
        
        let node = CardNode(cardId: id, cardType: .faceDownLarge)
        node.position = opponentCenterTarget()
        overlay.addChild(node)
        opponentMiniById[id] = node
        return node
    }
    
    // MARK: - Target Positions
    
    func localCenterTarget() -> CGPoint {
        CGPoint(
            x: logicalFrame.midX - 90,
            y: logicalFrame.midY
        )
    }
    
    func opponentCenterTarget() -> CGPoint {
        CGPoint(
            x: logicalFrame.midX + 90,
            y: logicalFrame.midY
        )
    }
    
    // MARK: - Cleanup after Reveal
    
    func clearCenteredCard(localId: CardId, oppId: CardId) {
        cardNodesById[localId] = nil
        opponentMiniById[oppId] = nil
    }
    
    func resetCenteredState() {
        centeredLocalCardId = nil
        centeredOpponentCardId = nil
    }
    
    // MARK: - Private Helpers
    
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
}
