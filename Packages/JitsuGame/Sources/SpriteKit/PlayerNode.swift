//
//  PlayerNode.swift
//  JitsuGame
//
//  Created by Tom Knighton on 24/02/2026.
//


import SpriteKit

public final class PlayerNode: SKNode {
    private let body = SKShapeNode(circleOfRadius: 44)
    private let beak = SKShapeNode()
    private let readyDot = SKShapeNode(circleOfRadius: 6)

    override public init() {
        super.init()

        body.lineWidth = 3
        body.strokeColor = .init(white: 0.25, alpha: 1.0)

        readyDot.fillColor = .systemGreen
        readyDot.strokeColor = .clear
        readyDot.position = CGPoint(x: 0, y: 56)
        readyDot.isHidden = true

        addChild(body)
        addChild(beak)
        addChild(readyDot)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }

    public func set(color: SKColor, facingRight: Bool) {
        body.fillColor = color

        let beakPath = CGMutablePath()
        if facingRight {
            beakPath.move(to: CGPoint(x: 34, y: 0))
            beakPath.addLine(to: CGPoint(x: 58, y: 6))
            beakPath.addLine(to: CGPoint(x: 58, y: -6))
        } else {
            beakPath.move(to: CGPoint(x: -34, y: 0))
            beakPath.addLine(to: CGPoint(x: -58, y: 6))
            beakPath.addLine(to: CGPoint(x: -58, y: -6))
        }
        beakPath.closeSubpath()

        beak.path = beakPath
        beak.fillColor = .orange
        beak.strokeColor = .clear
    }

    public func setReady(_ ready: Bool) {
        readyDot.isHidden = !ready
    }
}
