//
//  CardColour+Color.swift
//  JitsuGame
//
//  Created by Tom Knighton on 11/03/2026.
//

import JitsuCore
import SpriteKit

public func colour(for cardColour: Card.Colour) -> UIColor {
    switch cardColour {
    case .red:
        return .red
    case .blue:
        return .blue
    case .yellow:
        return .yellow
    case .green:
        return .green
    case .orange:
        return .orange
    case .purple:
        return .purple
    }
}
