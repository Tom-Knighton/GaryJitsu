//
//  RNG.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Foundation

public protocol DeterministicRNG: Sendable {
    mutating func next() -> UInt64
}

public extension DeterministicRNG {
    mutating func nextInt(upperBound: Int) -> Int {
        precondition(upperBound > 0)
        let ub = UInt64(upperBound)
        let limit = UInt64.max - (UInt64.max % ub)
        var x: UInt64
        repeat { x = next() } while x >= limit
        return Int(x % ub)
    }
    
    mutating func shuffle<T>(_ array: inout [T]) {
        guard array.count > 1 else { return }
        for i in stride(from: array.count - 1, through: 1, by: -1) {
            let j = nextInt(upperBound: i + 1)
            if i != j { array.swapAt(i, j) }
        }
    }
}

public struct `Xoshiro256**`: DeterministicRNG, Hashable, Sendable, Codable {
    private var s0: UInt64
    private var s1: UInt64
    private var s2: UInt64
    private var s3: UInt64
    
    public init(seed: UInt64) {
        var sm = SplitMix64(state: seed)
        self.s0 = sm.next()
        self.s1 = sm.next()
        self.s2 = sm.next()
        self.s3 = sm.next()
        if (s0 | s1 | s2 | s3) == 0 {
            self.s0 = 0x9E3779B97F4A7C15
        }
    }
    
    public mutating func next() -> UInt64 {
        let result = rotl((s1 &* 5), by: 7) &* 9
        let t = s1 << 17
        
        s2 ^= s0
        s3 ^= s1
        s1 ^= s2
        s0 ^= s3
        
        s2 ^= t
        s3 = rotl(s3, by: 45)
        
        return result
    }
    
    private func rotl(_ x: UInt64, by k: UInt64) -> UInt64 {
        (x << k) | (x >> (64 - k))
    }
    
    private struct SplitMix64: Sendable {
        var state: UInt64
        
        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
    }
}
