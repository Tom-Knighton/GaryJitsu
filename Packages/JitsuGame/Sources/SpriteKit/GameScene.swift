
import SpriteKit
import JitsuCore
import JitsuMatch

public final class GameScene: SKScene {
    
    // MARK: - Public API
    
    public var onSelectCard: ((CardId) -> Void)?
    
    // MARK: - Logical layout
    
    public enum Layout {
        public static let logicalSize = CGSize(width: 960, height: 540)
        
        public static let baseTrayHeight: CGFloat = 140
        public static let maxBottomMarginTrayExpansion: CGFloat = 84
        
        public static let arenaTopInset: CGFloat = 68
        public static let arenaBottomInset: CGFloat = 156
        
        public static let playerHorizontalInset: CGFloat = 220
        
        public static let trayBottomInset: CGFloat = 10
        
        public static let bottomHandVerticalFactor: CGFloat = 0.52
        
        public static let opponentMiniRightInset: CGFloat = 22
        public static let opponentMiniVerticalFactor: CGFloat = 0.62
        
        public static let tokenTopInset: CGFloat = 50
        public static let tokenOuterInset: CGFloat = 32
    }
    
    public struct Viewport: Equatable {
        public let sceneSize: CGSize
        public let logicalSize: CGSize
        public let logicalFrame: CGRect
        public let margins: EdgeInsets
        
        public struct EdgeInsets: Equatable {
            public let top: CGFloat
            public let left: CGFloat
            public let bottom: CGFloat
            public let right: CGFloat
        }
        
        public init(sceneSize: CGSize, logicalSize: CGSize = Layout.logicalSize) {
            self.sceneSize = sceneSize
            self.logicalSize = logicalSize
            
            let extraWidth = max(0, sceneSize.width - logicalSize.width)
            let extraHeight = max(0, sceneSize.height - logicalSize.height)
            
            let horizontalMargin = extraWidth * 0.5
            
            let logicalFrame = CGRect(
                x: horizontalMargin,
                y: extraHeight,
                width: logicalSize.width,
                height: logicalSize.height
            )
            
            self.logicalFrame = logicalFrame
            self.margins = EdgeInsets(
                top: 0,
                left: horizontalMargin,
                bottom: extraHeight,
                right: horizontalMargin
            )
        }
    }
    
    // MARK: - Identity
    
    private let localPlayer: Player
    
    // MARK: - Viewport
    
    public private(set) var viewport: Viewport
    
    // MARK: - Render-loop state
    
    private var lastUpdateTime: TimeInterval = 0
    private var lastRenderedHash: Int?
    private var lastProcessedRevealSeq: UInt64 = 0
    private var lastPlayersCache: [Player]?
    
    private var isAnimating: Bool = false
    private var pendingState: GameState?
    private var pendingEffects: [Effect] = []
    
    private var hasMovedToView = false
    private var shouldStartIntro = false
    
    // MARK: - Scene graph
    
    private let world = SKNode()
    
    private let backgroundRoot = SKNode()
    private let backgroundImage = SKSpriteNode(imageNamed: "game_bg")
    private let gameRoot = SKNode()
    private let hudRoot = SKNode()
    private let overlay = SKNode()
    
    // MARK: Background layers
    
    private let backgroundFill = SKShapeNode()
    private let sideLeftBackdrop = SKShapeNode()
    private let sideRightBackdrop = SKShapeNode()
    private let bottomBackdrop = SKShapeNode()
    
    private var currentTrayRect: CGRect = .zero
        
    // MARK: Main scene content
    
    private let arena = SKNode()
    private let leftPlayer = PlayerNode()
    private let rightPlayer = PlayerNode()
    
    private let bottomTray = SKShapeNode()
    
    // MARK: Sub-components
    
    private let handRenderer = HandRenderer()
    private let tokenRenderer = TokenRenderer()
    private var revealAnimator: RevealAnimator?
    private var introAnimator: IntroAnimator?
    
    // MARK: Player positions
    private var leftPlayerRestPosition: CGPoint = .zero
    private var rightPlayerRestPosition: CGPoint = .zero
    
    // MARK: - Init
    
    public init(size: CGSize, localPlayer: Player) {
        self.localPlayer = localPlayer
        self.viewport = Viewport(sceneSize: size)
        
        super.init(size: size)
        
        scaleMode = .aspectFit
        anchorPoint = .zero
        
        revealAnimator = RevealAnimator(
            handRenderer: handRenderer,
            tokenRenderer: tokenRenderer,
            overlay: overlay,
            localPlayer: localPlayer
        )
        
        introAnimator = IntroAnimator(
            leftPlayer: leftPlayer,
            rightPlayer: rightPlayer,
            bottomCards: handRenderer.bottomCards,
            opponentMiniCards: handRenderer.opponentMiniCards
        )
        
        revealAnimator?.onCycleFinished = { [weak self] in
            self?.finishAnimationCycle()
        }
        
        handRenderer.onDealingComplete = { [weak self] _ in
            guard let self, let next = self.pendingState else { return }
            self.pendingState = nil
            self.pendingEffects = []
            self.apply(state: next)
        }
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        nil
    }
    
    // MARK: - Lifecycle
    
    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        hasMovedToView = true
        backgroundColor = .red
        
        addChild(world)
        world.addChild(backgroundRoot)
        world.addChild(gameRoot)
        world.addChild(hudRoot)
        world.addChild(overlay)
        
        setupBackground()
        setupGameContent()
        setupHud()
        layoutUI()
        
        Task { @MainActor in
            await leftPlayer.preload(anims: [.idleReady, .walk])
            await rightPlayer.preload(anims: [.idleReady, .walk])
        }
    }
    
    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        
        viewport = Viewport(sceneSize: size)
        layoutUI()
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
    
    // MARK: - Public Render Entry Point
    
    public func render(state: GameState, effects: [Effect] = []) {
        if lastRenderedHash == nil {
            apply(state: state)
            introAnimator?.beginIfNeeded()
            return
        }
        
        if isAnimating || !handRenderer.dealingCards.isEmpty {
            pendingState = state
            pendingEffects = effects
            return
        }
        
        let hash = state.hashValue
        if lastRenderedHash == hash {
            return
        }
        
        if let reveal = effects.firstRevealCards,
           state.globalSequence != lastProcessedRevealSeq {
            lastProcessedRevealSeq = state.globalSequence
            pendingState = state
            pendingEffects = effects
            isAnimating = true
            revealAnimator?.startRevealCycle(reveal: reveal, effects: effects)
            return
        }
        
        apply(state: state)
    }
    
    // MARK: - Setup
    
    private func setupBackground() {
        backgroundRoot.zPosition = -100
                
        gameRoot.zPosition = 0
        hudRoot.zPosition = 50
        overlay.zPosition = 100
        
        backgroundImage.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundImage.zPosition = -10
        backgroundRoot.addChild(backgroundImage)
        
        backgroundFill.strokeColor = .clear
        backgroundFill.fillColor = SKColor(red: 1, green: 0.08, blue: 0.14, alpha: 1)
        backgroundFill.zPosition = -20
        
        sideLeftBackdrop.strokeColor = .clear
        sideLeftBackdrop.fillColor = SKColor(red: 0.08, green: 1, blue: 0.19, alpha: 0.5)
        
        sideRightBackdrop.strokeColor = .clear
        sideRightBackdrop.fillColor = SKColor(red: 0.08, green: 1, blue: 0.19, alpha: 0.5)
        
        bottomBackdrop.strokeColor = .clear
        bottomBackdrop.fillColor = SKColor(red: 1, green: 0.07, blue: 0.11, alpha: 1)
        
        backgroundRoot.addChild(backgroundFill)
        backgroundRoot.addChild(sideLeftBackdrop)
        backgroundRoot.addChild(sideRightBackdrop)
        backgroundRoot.addChild(bottomBackdrop)
    }
    
    private func setupGameContent() {
        gameRoot.addChild(arena)
        arena.addChild(leftPlayer)
        arena.addChild(rightPlayer)
        
        leftPlayer.set(color: .yellow, facingRight: true)
        rightPlayer.set(color: .green, facingRight: false)
        
        bottomTray.isAntialiased = true
        bottomTray.strokeColor = SKColor(white: 1, alpha: 0.14)
        bottomTray.lineWidth = 2
        bottomTray.fillColor = SKColor(red: 0.05, green: 0.06, blue: 0.09, alpha: 0.94)
        bottomTray.zPosition = 10
        
        gameRoot.addChild(bottomTray)
        
        handRenderer.bottomCards.zPosition = 11
        handRenderer.opponentMiniCards.zPosition = 11
        gameRoot.addChild(handRenderer.bottomCards)
        gameRoot.addChild(handRenderer.opponentMiniCards)
        
        handRenderer.sceneNode = self
    }
    
    private func setupHud() {
        hudRoot.addChild(tokenRenderer.container)
    }
    
    // MARK: - Layout
    
    private func layoutUI() {
        let sceneBounds = CGRect(origin: .zero, size: size)
        let logical = viewport.logicalFrame
        
        layoutBackground(sceneBounds: sceneBounds, logical: logical)
        layoutArena(logical: logical)
        layoutTray(logical: logical)
        layoutHands(logical: logical)
        layoutTokens(logical: logical)
        
        introAnimator?.updateLayout(
            sceneBounds: CGRect(origin: .zero, size: size),
            arenaPosition: arena.position,
            leftFinalPosition: leftPlayerRestPosition,
            rightFinalPosition: rightPlayerRestPosition
        )
    }
    
    private func layoutBackground(sceneBounds: CGRect, logical: CGRect) {
        backgroundImage.position = CGPoint(x: sceneBounds.midX, y: sceneBounds.midY)
        backgroundImage.size = sceneBounds.size
        
        backgroundFill.path = CGPath(rect: sceneBounds, transform: nil)
        
        if viewport.margins.left > 0 {
            let leftRect = CGRect(
                x: sceneBounds.minX,
                y: sceneBounds.minY,
                width: viewport.margins.left,
                height: sceneBounds.height
            )
            sideLeftBackdrop.path = CGPath(rect: leftRect, transform: nil)
            
            let rightRect = CGRect(
                x: logical.maxX,
                y: sceneBounds.minY,
                width: viewport.margins.right,
                height: sceneBounds.height
            )
            sideRightBackdrop.path = CGPath(rect: rightRect, transform: nil)
        } else {
            sideLeftBackdrop.path = nil
            sideRightBackdrop.path = nil
        }
        
        if viewport.margins.bottom > 0 {
            let bottomRect = CGRect(
                x: logical.minX,
                y: 0,
                width: logical.width,
                height: logical.minY
            )
            bottomBackdrop.path = CGPath(rect: bottomRect, transform: nil)
        } else {
            bottomBackdrop.path = nil
        }
    }
    
    private func layoutArena(logical: CGRect) {
        let arenaMidY = logical.midY + 8
        arena.position = CGPoint(x: logical.midX, y: arenaMidY)
        
        leftPlayerRestPosition = CGPoint(
            x: -Layout.playerHorizontalInset,
            y: -125
        )
        
        rightPlayerRestPosition = CGPoint(
            x: Layout.playerHorizontalInset,
            y: -125
        )
        
        let introStarted = introAnimator?.hasStartedOrCompleted ?? false
        if !introStarted {
            leftPlayer.position = leftPlayerRestPosition
            rightPlayer.position = rightPlayerRestPosition
        }
    }
    
    private func layoutTray(logical: CGRect) {
        let trayExpansion = min(
            viewport.margins.bottom,
            Layout.maxBottomMarginTrayExpansion
        )
        
        let trayHeight = Layout.baseTrayHeight + trayExpansion
        
        let trayRect = CGRect(
            x: logical.minX,
            y: logical.minY - (trayHeight - Layout.baseTrayHeight) + Layout.trayBottomInset,
            width: logical.width,
            height: trayHeight
        )
        
        currentTrayRect = trayRect
        
        bottomTray.path = CGPath(
            roundedRect: trayRect,
            cornerWidth: 22,
            cornerHeight: 22,
            transform: nil
        )
        bottomTray.position = .zero
    }
    
    private func layoutHands(logical: CGRect) {
        handRenderer.logicalFrame = logical
        
        let trayRect = currentTrayRect
        guard !trayRect.isEmpty else { return }
        
        handRenderer.bottomCards.position = CGPoint(
            x: trayRect.minX + trayRect.width * 0.30,
            y: trayRect.minY + trayRect.height * 0.52
        )
        
        handRenderer.opponentMiniCards.position = CGPoint(
            x: trayRect.maxX - 22,
            y: trayRect.minY + trayRect.height * 0.62
        )
    }
    
    private func layoutTokens(logical: CGRect) {
        guard let players = lastPlayersCache else { return }
        
        tokenRenderer.ensureStacks(players: players, local: localPlayer)
        
        if players.count >= 2 {
            let localX = max(
                24,
                logical.minX - max(0, viewport.margins.left * 0.5)
            )
            
            let remoteX = min(
                size.width - 24,
                logical.maxX + max(0, viewport.margins.right * 0.5)
            )
            
            let y = logical.maxY - Layout.tokenTopInset
            
            tokenRenderer.positionStacks(
                players: players,
                local: localPlayer,
                localPosition: CGPoint(x: localX, y: y),
                remotePosition: CGPoint(x: remoteX, y: y)
            )
        } else {
            tokenRenderer.positionStacks(
                players: players,
                local: localPlayer,
                localPosition: CGPoint(
                    x: logical.minX + Layout.tokenOuterInset,
                    y: logical.maxY - Layout.tokenTopInset
                ),
                remotePosition: CGPoint(
                    x: logical.maxX - Layout.tokenOuterInset,
                    y: logical.maxY - Layout.tokenTopInset
                )
            )
        }
    }
    
    // MARK: - Apply State
    
    private func apply(state: GameState) {
        let players = state.config.players
        guard let opponent = players.first(where: { $0 != localPlayer }) else { return }
        
        handRenderer.renderBottomHand(state: state, player: localPlayer)
        handRenderer.renderOpponentHand(state: state, player: opponent)
        handRenderer.renderSelections(
            state: state,
            local: localPlayer,
            opponent: opponent,
            overlay: overlay,
            leftPlayer: leftPlayer,
            rightPlayer: rightPlayer
        )
        
        lastPlayersCache = players
        layoutTokens(logical: viewport.logicalFrame)
        tokenRenderer.syncFromState(state, players: players)
        
        lastRenderedHash = state.hashValue
    }
    
    // MARK: - Animation Cycle End
    
    private func finishAnimationCycle() {
        isAnimating = false
        
        if let next = pendingState {
            pendingState = nil
            pendingEffects = []
            apply(state: next)
        }
    }
    
    // MARK: - Touch Handling
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let location = touch.location(in: self)
        let hit = atPoint(location)
        
        if let card = hit.closestAncestor(of: CardNode.self), card.isInBottomTray {
            onSelectCard?(card.cardId)
        }
    }
}
