//
//  GameLayout.swift
//  JitsuGame
//
//  Created by Tom Knighton on 07/03/2026.
//


import CoreGraphics
import UIKit

enum GameLayout {
    static let logicalSize = CGSize(width: 960, height: 540)
}

struct GameViewport: Equatable {
    let sceneSize: CGSize
    let logicalSize: CGSize
    let logicalFrame: CGRect
    let margins: UIEdgeInsets

    init(sceneSize: CGSize, logicalSize: CGSize = GameLayout.logicalSize) {
        self.sceneSize = sceneSize
        self.logicalSize = logicalSize

        let extraWidth = max(0, sceneSize.width - logicalSize.width)
        let extraHeight = max(0, sceneSize.height - logicalSize.height)

        // Wider screens: center horizontally
        let leftRight = extraWidth * 0.5

        // Taller/narrower screens: bias extra height to the bottom
        // so the player does not see “more” above the important area.
        let logicalOrigin = CGPoint(x: leftRight, y: extraHeight)

        self.logicalFrame = CGRect(origin: logicalOrigin, size: logicalSize)
        self.margins = UIEdgeInsets(
            top: 0,
            left: leftRight,
            bottom: extraHeight,
            right: leftRight
        )
    }
}
