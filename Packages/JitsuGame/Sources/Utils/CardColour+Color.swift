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
        return .init(red: 0.89, green: 0.24, blue: 0.15, alpha: 1.00)
    case .blue:
        return .init(red: 0.07, green: 0.28, blue: 0.63, alpha: 1.00)
    case .yellow:
        return .init(red: 0.98, green: 0.93, blue: 0.16, alpha: 1.00)
    case .green:
        return .init(red: 0.38, green: 0.73, blue: 0.27, alpha: 1.00)
    case .orange:
        return .init(red: 0.97, green: 0.58, blue: 0.16, alpha: 1.00)
    case .purple:
        return .init(red: 0.64, green: 0.60, blue: 0.80, alpha: 1.00)
    }
}
