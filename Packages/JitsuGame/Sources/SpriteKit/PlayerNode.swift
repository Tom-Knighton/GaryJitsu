//
//  PlayerNode.swift
//  JitsuGame
//
//  Created by Tom Knighton on 24/02/2026.
//


import SpriteKit

public final class PlayerNode: SKNode {
    public enum Anim: Hashable, CaseIterable {
        case idleReady
        case walk
    }
    
    public struct AnimSpec: Hashable {
        public let atlasName: String
        public let prefix: String
        public let fps: Double
        public let loops: Bool
        public let size: CGSize
        public let yOffset: Double
        
        public init(atlasName: String, prefix: String, fps: Double, loops: Bool, size: CGSize = .init(width: 150, height: 200), yOffset: Double = 0) {
            self.atlasName = atlasName
            self.prefix = prefix
            self.fps = fps
            self.loops = loops
            self.size = size
            self.yOffset = yOffset
        }
    }
    
    public var animTable: [Anim: AnimSpec] = [
        .idleReady: .init(atlasName: "Character_Base", prefix: "ready_idle_", fps: 60, loops: true, size: CGSize(width: 150, height: 200), yOffset: 0),
        .walk:      .init(atlasName: "Character_Intro", prefix: "walk_", fps: 30, loops: true, size: .init(width: 115, height: 200), yOffset: 0.05),
    ]
    
    // MARK: - Internals
    private let sprite: SKSpriteNode
    private let animator = FrameAnimator()
    
    private let readyDot = SKShapeNode(circleOfRadius: 6)
    
    private var currentAnim: Anim?
    private var facingRight: Bool = true
    
    private var atlasCache: [String: SKTextureAtlas] = [:]
    private var framesCache: [AnimSpec: [SKTexture]] = [:]
    
    public init(initialAnim: Anim = .idleReady) {
        self.sprite = SKSpriteNode(color: .clear, size: CGSize(width: 150, height: 200))
        super.init()
        
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0)
        addChild(sprite)
        addChild(readyDot)
        
        play(initialAnim, restartIfSame: true)
        
        readyDot.fillColor = .systemGreen
        readyDot.strokeColor = .clear
        readyDot.position = CGPoint(x: 0, y: 56)
        readyDot.isHidden = true
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }
    
    public func play(_ anim: Anim, restartIfSame: Bool = false) {
        guard let spec = animTable[anim] else { return }
        if !restartIfSame, currentAnim == anim { return }
        
        let frames = resolveFrames(for: spec)
        guard let first = frames.first else { return }
        
        sprite.texture = first
        
        let clip = FrameAnimator.Clip(atlasName: spec.atlasName, prefix: spec.prefix, fps: spec.fps, loops: spec.loops)
        sprite.size = spec.size
        sprite.anchorPoint = .init(x: 0.5, y: spec.yOffset)
        animator.play(clip, frames: frames, restartIfSame: restartIfSame)
        currentAnim = anim
    }
    
    public func update(dt: TimeInterval) {
        animator.update(dt: dt) { [weak self] tex in
            guard let self else { return }
            self.sprite.texture = tex
        }
    }
    
    public func preload(anims: [Anim]) async {
        let specs = anims.compactMap { animTable[$0] }
        let uniqueAtlasNames = Array(Set(specs.map(\.atlasName)))
        
        let atlases = uniqueAtlasNames.map { makeAtlas(named: $0) }
        
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            SKTextureAtlas.preloadTextureAtlases(atlases) {
                cont.resume()
            }
        }
        
        let textures: [SKTexture] = specs.flatMap { resolveFrames(for: $0) }
        
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            SKTexture.preload(textures) {
                cont.resume()
            }
        }
    }
    
    
    public func set(color: SKColor, facingRight: Bool) {
        sprite.colorBlendFactor = 0.0
        self.facingRight = facingRight
        sprite.xScale = abs(sprite.xScale) * (facingRight ? 1 : -1)
        sprite.color = color
        
        sprite.drawBorder(color: UIColor(cgColor: color.cgColor), width: 1)
    }
    
    public func setReady(_ ready: Bool) {
        readyDot.isHidden = !ready
    }
    
    private func makeAtlas(named name: String) -> SKTextureAtlas {
        if let cached = atlasCache[name] { return cached }
        
        let atlas: SKTextureAtlas
        atlas = SKTextureAtlas(named: name)
        
        atlasCache[name] = atlas
        return atlas
    }
    
    private func resolveFrames(for spec: AnimSpec) -> [SKTexture] {
        if let cached = framesCache[spec] { return cached }
        
        let atlas = makeAtlas(named: spec.atlasName)
        
        let names = atlas.textureNames
            .filter { $0.hasPrefix(spec.prefix) }
            .sorted()
        
        let frames = names.map { name -> SKTexture in
            let t = atlas.textureNamed(name)
            t.filteringMode = .nearest
            return t
        }
        
        framesCache[spec] = frames
        return frames
    }
}

extension SKNode {
    func drawBorder(color: UIColor, width: CGFloat) {
        let shapeNode = SKShapeNode(rect: frame)
        shapeNode.fillColor = .clear
        shapeNode.strokeColor = color
        shapeNode.lineWidth = width
        addChild(shapeNode)
    }
}

public final class FrameAnimator {
    public struct Clip: Hashable {
        public let atlasName: String
        public let prefix: String
        public let fps: Double
        public let loops: Bool
        
        public init(atlasName: String, prefix: String, fps: Double, loops: Bool) {
            self.atlasName = atlasName
            self.prefix = prefix
            self.fps = fps
            self.loops = loops
        }
    }
    
    private var clip: Clip?
    private var frames: [SKTexture] = []
    private var frameIndex: Int = 0
    private var accumulator: TimeInterval = 0
    
    public init() {}
    
    public func play(
        _ clip: Clip,
        frames: [SKTexture],
        restartIfSame: Bool = false
    ) {
        if !restartIfSame, self.clip == clip { return }
        self.clip = clip
        self.frames = frames
        self.frameIndex = 0
        self.accumulator = 0
    }
    
    public func update(dt: TimeInterval, applyTexture: (SKTexture) -> Void) {
        guard let clip, !frames.isEmpty else { return }
        
        let clamped = min(dt, 1.0 / 15.0)
        accumulator += clamped
        
        let step = 1.0 / clip.fps
        while accumulator >= step {
            accumulator -= step
            frameIndex += 1
            
            if frameIndex >= frames.count {
                if clip.loops {
                    frameIndex = 0
                } else {
                    frameIndex = frames.count - 1
                    break
                }
            }
        }
        
        applyTexture(frames[frameIndex])
    }
}
