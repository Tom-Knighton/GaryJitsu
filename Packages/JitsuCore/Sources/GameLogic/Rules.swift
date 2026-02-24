//
//  Rules.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Foundation

public enum Rules {
    public static func compare(_ a: Card, _ b: Card) -> CardComparisonResult {
        if a.element == b.element {
            if a.level == b.level { return .draw }
            return a.level > b.level ? .win : .lose
        }
        
        switch (a.element, b.element) {
        case (.fire, .snow), (.snow, .water), (.water, .fire):
            return .win
        default:
            return .lose
        }
    }
}
