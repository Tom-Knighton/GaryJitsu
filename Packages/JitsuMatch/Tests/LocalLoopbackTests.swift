import Foundation
import Testing
@testable import JitsuMatch
import JitsuCore

@Suite("Local loopback")
struct LocalLoopbackTests {
    
    // MARK: - Transport-only
    
    @Test
    func endpointsReceiveSameOrderedEnvelopes_withoutSessions() async throws {
        let cfg = TestSupport.makeConfig(seed: 999, initialHandSize: 5)
        let initial = Engine.makeInitialState(config: cfg).state
        
        let built = await LocalMatchFactory.build(initialState: initial, p1: TestSupport.p1, p2: TestSupport.p2)
        let e1 = built.e1
        let e2 = built.e2
        
        async let a = collect(envelopesFrom: e1, count: 4)
        async let b = collect(envelopesFrom: e2, count: 4)
        
        let p1Card1 = initial.playerZone(TestSupport.p1).hand[0].id
        let p2Card1 = initial.playerZone(TestSupport.p2).hand[0].id
        let p1Card2 = initial.playerZone(TestSupport.p1).hand[1].id
        let p2Card2 = initial.playerZone(TestSupport.p2).hand[1].id
        
        await e1.send(.selectCard(player: TestSupport.p1, card: p1Card1), stateHashBefore: nil)
        await e2.send(.selectCard(player: TestSupport.p2, card: p2Card1), stateHashBefore: nil)
        await e1.send(.selectCard(player: TestSupport.p1, card: p1Card2), stateHashBefore: nil)
        await e2.send(.selectCard(player: TestSupport.p2, card: p2Card2), stateHashBefore: nil)
        
        let envs1 = try await a
        let envs2 = try await b
        
        #expect(envs1 == envs2)
        #expect(envs1.map(\.seq) == [1, 2, 3, 4])
    }
    
    @Test
    func concurrentPairSubmits_produceNoDroppedOrDuplicateSeq_withoutSessions() async throws {
        let cfg = TestSupport.makeConfig(seed: 42, initialHandSize: 10)
        let initial = Engine.makeInitialState(config: cfg).state
        
        let built = await LocalMatchFactory.build(initialState: initial, p1: TestSupport.p1, p2: TestSupport.p2)
        let e1 = built.e1
        let e2 = built.e2
        
        let iterations = 5
        async let received = collect(envelopesFrom: e1, count: iterations * 2)
        
        let p1Cards = Array(initial.playerZone(TestSupport.p1).hand.prefix(iterations)).map(\.id)
        let p2Cards = Array(initial.playerZone(TestSupport.p2).hand.prefix(iterations)).map(\.id)
        
        for i in 0..<iterations {
            let c1 = p1Cards[i]
            let c2 = p2Cards[i]
            let endpoint1 = e1
            let endpoint2 = e2
            
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await endpoint1.send(.selectCard(player: TestSupport.p1, card: c1), stateHashBefore: nil) }
                group.addTask { await endpoint2.send(.selectCard(player: TestSupport.p2, card: c2), stateHashBefore: nil) }
            }
        }
        
        let envs = try await received
        #expect(envs.count == iterations * 2)
        
        let seqs = envs.map(\.seq)
        #expect(Set(seqs).count == iterations * 2)
        #expect(seqs.min() == 1)
        #expect(seqs.max() == UInt64(iterations * 2))
    }
    
    @Test
    func stateHashBeforeIsPreserved_withoutSessions() async throws {
        let cfg = TestSupport.makeConfig(seed: 7, initialHandSize: 5)
        let initial = Engine.makeInitialState(config: cfg).state
        
        let built = await LocalMatchFactory.build(initialState: initial, p1: TestSupport.p1, p2: TestSupport.p2)
        let e1 = built.e1
        
        async let envs = collect(envelopesFrom: e1, count: 1)
        
        let c1 = initial.playerZone(TestSupport.p1).hand[0].id
        await e1.send(.selectCard(player: TestSupport.p1, card: c1), stateHashBefore: 123_456)
        
        let first = try await envs.first
        #expect(first?.stateHashBefore == 123_456)
    }
    
    // MARK: - Session-only (no envelope collection from the same endpoints)
    
    @Test
    func sessionsAdvanceSeqAndConverge() async throws {
        let cfg = TestSupport.makeConfig(seed: 123, initialHandSize: 5)
        let initial = Engine.makeInitialState(config: cfg).state
        
        let built = await LocalMatchFactory.build(initialState: initial, p1: TestSupport.p1, p2: TestSupport.p2)
        let p1 = built.p1
        let p2 = built.p2
        
        await MainActor.run {
            p1.start()
            p2.start()
        }
        
        let c1 = try await firstCardID(for: TestSupport.p1, in: p1)
        await MainActor.run { p1.submit(.selectCard(player: TestSupport.p1, card: c1)) }
        
        let c2 = try await firstCardID(for: TestSupport.p2, in: p2)
        await MainActor.run { p2.submit(.selectCard(player: TestSupport.p2, card: c2)) }
        
        try await waitAppliedSeq(p1, atLeast: 2)
        try await waitAppliedSeq(p2, atLeast: 2)
        
        let s1 = await state(of: p1)
        let s2 = await state(of: p2)
        #expect(s1 == s2)
    }
    
    @Test
    func sessionSubmitIsNotOptimistic_seqDoesNotAdvanceSynchronously() async throws {
        let cfg = TestSupport.makeConfig(seed: 99, initialHandSize: 5)
        let initial = Engine.makeInitialState(config: cfg).state
        
        let built = await LocalMatchFactory.build(initialState: initial, p1: TestSupport.p1, p2: TestSupport.p2)
        let p1 = built.p1
        
        await MainActor.run { p1.start() }
        
        let beforeSeq = await appliedSeq(of: p1)
        let card = try await firstCardID(for: TestSupport.p1, in: p1)
        
        await MainActor.run { p1.submit(.selectCard(player: TestSupport.p1, card: card)) }
        
        let immediateSeq = await appliedSeq(of: p1)
        #expect(immediateSeq == beforeSeq)
        
        try await waitAppliedSeq(p1, atLeast: beforeSeq + 1)
    }
}

// MARK: - Helpers

private func collect(
    envelopesFrom endpoint: any TransportEndpoint,
    count: Int
) async throws -> [IntentEnvelope] {
    var result: [IntentEnvelope] = []
    var iterator = endpoint.incomingEnvelopes().makeAsyncIterator()
    while result.count < count {
        guard let next = await iterator.next() else {
            throw CollectionError.streamTerminatedEarly
        }
        result.append(next)
    }
    return result
}

private enum CollectionError: Error {
    case streamTerminatedEarly
}

private func state(of session: Session) async -> GameState {
    await MainActor.run { session.state }
}

private func appliedSeq(of session: Session) async -> UInt64 {
    await MainActor.run { session.lastAppliedSeq }
}

private func firstCardID(for player: Player, in session: Session) async throws -> CardId {
    try await MainActor.run {
        let hand = session.state.playerZone(player).hand
        guard let first = hand.first else { throw CardPickError.emptyHand }
        return first.id
    }
}

private enum CardPickError: Error { case emptyHand }

private func waitAppliedSeq(_ session: Session, atLeast target: UInt64) async throws {
    try await waitUntil(timeoutSeconds: 1.0) {
        await appliedSeq(of: session) >= target
    }
}

private func waitUntil(
    timeoutSeconds: TimeInterval,
    pollSeconds: TimeInterval = 0.005,
    _ predicate: @escaping @Sendable () async -> Bool
) async throws {
    let deadline = Date().addingTimeInterval(timeoutSeconds)
    while Date() < deadline {
        if await predicate() { return }
        try await Task.sleep(nanoseconds: UInt64(pollSeconds * 1_000_000_000))
    }
    throw WaitError.timedOut
}

private enum WaitError: Error { case timedOut }
