//
//  RNGTests.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Testing
@testable import JitsuCore

@Test
func rng_same_seed_produces_same_sequence() {
    var a = `Xoshiro256**`(seed: 123)
    var b = `Xoshiro256**`(seed: 123)
    
    var seqA: [UInt64] = []
    var seqB: [UInt64] = []
    seqA.reserveCapacity(10)
    seqB.reserveCapacity(10)
    
    for _ in 0..<10 {
        seqA.append(a.next())
        seqB.append(b.next())
    }
    
    #expect(seqA == seqB)
}

@Test
func rng_shuffle_is_deterministic_for_same_seed() {
    var a = `Xoshiro256**`(seed: 999)
    var b = `Xoshiro256**`(seed: 999)
    
    var xs1 = Array(0..<50)
    var xs2 = Array(0..<50)
    
    a.shuffle(&xs1)
    b.shuffle(&xs2)
    
    #expect(xs1 == xs2)
}

@Test
func rng_nextInt_bounds() {
    var rng = `Xoshiro256**`(seed: 1)
    for _ in 0..<1_000 {
        let v = rng.nextInt(upperBound: 7)
        #expect(v >= 0)
        #expect(v < 7)
    }
}
