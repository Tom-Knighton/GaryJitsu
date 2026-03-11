//
//  TokenTrackTests.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Testing
@testable import JitsuCore

@Test
func tokenTrack_counts_and_awards_are_consistent() {
    var track = TokenTrack()
    
    let c1 = Card(id: "c1", element: .fire, level: 2, colour: .red, artKey: "fire_2")
    let c2 = Card(id: "c2", element: .fire, level: 9, colour: .red, artKey: "fire_9")
    let c3 = Card(id: "c3", element: .water, level: 1, colour: .red, artKey: "water_1")
    
    track.award(from: c1, sequence: 1)
    track.award(from: c2, sequence: 1)
    track.award(from: c3, sequence: 1)
    
    #expect(track.awards.map(\.cardId) == ["c1", "c2", "c3"])
    #expect(track.counts[.init(stringLiteral: "fire_red")] == 2)
    #expect(track.counts[.init(stringLiteral: "water_red")] == 1)
    #expect(track.counts[.init(stringLiteral: "snow_red")] == nil)
}

@Test
func tokenTrack_three_of_same_element_same_colour_is_not_win() {
    var track = TokenTrack()
    track.award(from: Card(id: "c1", element: .snow, level: 1, colour: .red), sequence: 1)
    track.award(from: Card(id: "c2", element: .snow, level: 2, colour: .red), sequence: 1)
    track.award(from: Card(id: "c3", element: .snow, level: 3, colour: .red), sequence: 1)
    
    #expect(!track.hasThreeOfSameElementDifferentColours())
    #expect(!track.isWinning())
    #expect(!track.hasThreeDifferentElementsDifferentColours())
}

@Test
func tokenTrack_three_of_same_element_different_colour_is_win() {
    var track = TokenTrack()
    track.award(from: Card(id: "c1", element: .snow, level: 1, colour: .red), sequence: 1)
    track.award(from: Card(id: "c2", element: .snow, level: 2, colour: .blue), sequence: 1)
    track.award(from: Card(id: "c3", element: .snow, level: 3, colour: .green), sequence: 1)
    
    #expect(track.hasThreeOfSameElementDifferentColours())
    #expect(track.isWinning())
    #expect(!track.hasThreeDifferentElementsDifferentColours())
}

@Test
func tokenTrack_three_different_elements_same_colour_is_not_win() {
    var track = TokenTrack()
    track.award(from: Card(id: "c1", element: .fire, level: 1, colour: .red), sequence: 1)
    track.award(from: Card(id: "c2", element: .water, level: 1, colour: .red), sequence: 1)
    track.award(from: Card(id: "c3", element: .snow, level: 1, colour: .red), sequence: 1)
    track.award(from: Card(id: "c4", element: .snow, level: 1, colour: .blue), sequence: 1)
    
    #expect(!track.hasThreeDifferentElementsDifferentColours())
    #expect(!track.isWinning())
    #expect(!track.hasThreeOfSameElementDifferentColours())
}

@Test
func tokenTrack_three_different_elements_different_colours_is_win() {
    var track = TokenTrack()
    track.award(from: Card(id: "c1", element: .fire, level: 1, colour: .red), sequence: 1)
    track.award(from: Card(id: "c2", element: .water, level: 1, colour: .blue), sequence: 1)
    track.award(from: Card(id: "c3", element: .water, level: 1, colour: .red), sequence: 1)
    track.award(from: Card(id: "c4", element: .snow, level: 1, colour: .green), sequence: 1)
    track.award(from: Card(id: "c5", element: .snow, level: 1, colour: .red), sequence: 1)
    track.award(from: Card(id: "c6", element: .snow, level: 1, colour: .green), sequence: 1)
    
    #expect(track.hasThreeDifferentElementsDifferentColours())
    #expect(track.isWinning())
    #expect(!track.hasThreeOfSameElementDifferentColours())
}

