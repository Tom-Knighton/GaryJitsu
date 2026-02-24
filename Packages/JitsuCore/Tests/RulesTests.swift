//
//  CoreTests.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//
import Testing
@testable import JitsuCore

@Test
func rules_element_advantages() {
    let fire = Card(id: "f", element: .fire, level: 1)
    let water = Card(id: "w", element: .water, level: 1)
    let snow = Card(id: "s", element: .snow, level: 1)
    
    #expect(Rules.compare(fire, snow) == .win)
    #expect(Rules.compare(snow, water) == .win)
    #expect(Rules.compare(water, fire) == .win)
    
    #expect(Rules.compare(snow, fire) == .lose)
    #expect(Rules.compare(water, snow) == .lose)
    #expect(Rules.compare(fire, water) == .lose)
}

@Test
func rules_same_element_power_tie_and_compare() {
    let f1 = Card(id: "f1", element: .fire, level: 1)
    let f1b = Card(id: "f1b", element: .fire, level: 1)
    let f3 = Card(id: "f3", element: .fire, level: 3)
    
    #expect(Rules.compare(f1, f1b) == .draw)
    #expect(Rules.compare(f3, f1) == .win)
    #expect(Rules.compare(f1, f3) == .lose)
}
