//
//  FrameAnimator.swift
//  JitsuGame
//
//  Created by Tom Knighton on 24/02/2026.
//

import SpriteKit

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
