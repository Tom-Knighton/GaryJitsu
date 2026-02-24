//
//  LocalMatchFactory.swift
//  JitsuMatch
//
//  Created by Tom Knighton on 24/02/2026.
//

import Foundation
import JitsuCore

public enum LocalMatchFactory {
    public struct Built {
        public let host: LocalHost
        public let hub: LocalTransportHub
        public let p1: Session
        public let p2: Session
        public let e1: LocalTransportEndpoint
        public let e2: LocalTransportEndpoint
    }
    
    public static func build(initialState: GameState, p1: Player, p2: Player) async -> Built {
        let host = LocalHost(initialState: initialState)
        let hub = LocalTransportHub(host: host)
        
        let e1 = await hub.connect(playerId: p1)
        let e2 = await hub.connect(playerId: p2)
        
        let s1 = await Session(initialState: initialState, endpoint: e1)
        let s2 = await Session(initialState: initialState, endpoint: e2)
        
        return Built(host: host, hub: hub, p1: s1, p2: s2, e1: e1, e2: e2)
    }
}
