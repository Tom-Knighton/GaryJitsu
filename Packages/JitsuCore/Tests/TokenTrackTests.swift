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
    
    let c1 = Card(id: "c1", element: .fire, level: 2, artKey: "fire_2")
    let c2 = Card(id: "c2", element: .fire, level: 9, artKey: "fire_9")
    let c3 = Card(id: "c3", element: .water, level: 1, artKey: "water_1")
    
    track.award(from: c1, sequence: 1)
    track.award(from: c2, sequence: 1)
    track.award(from: c3, sequence: 1)
    
    #expect(track.awards.map(\.cardId) == ["c1", "c2", "c3"])
    #expect(track.counts[.fire] == 2)
    #expect(track.counts[.water] == 1)
    #expect(track.counts[.snow] == nil)
}

@Test
func tokenTrack_three_of_same_is_win() {
    var track = TokenTrack()
    track.award(from: Card(id: "c1", element: .snow, level: 1), sequence: 1)
    track.award(from: Card(id: "c2", element: .snow, level: 2), sequence: 1)
    track.award(from: Card(id: "c3", element: .snow, level: 3), sequence: 1)
    
    #expect(track.hasThreeOfSame())
    #expect(track.isWinning())
    #expect(!track.hasThreeDifferent())
}

@Test
func tokenTrack_three_different_is_win() {
    var track = TokenTrack()
    track.award(from: Card(id: "c1", element: .fire, level: 1), sequence: 1)
    track.award(from: Card(id: "c2", element: .water, level: 1), sequence: 1)
    track.award(from: Card(id: "c3", element: .snow, level: 1), sequence: 1)
    
    #expect(track.hasThreeDifferent())
    #expect(track.isWinning())
    #expect(!track.hasThreeOfSame())
}
