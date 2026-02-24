//
//  EngineResolutionTests.swift
//  JitsuCore
//
//  Created by Tom Knighton on 23/02/2026.
//

import Testing
@testable import JitsuCore

@Test
func round_resolution_discards_selected_cards_and_draws_one_each() {
    var s = TestSupport.initialState(seed: 42, initialHandSize: 5)
    
    let p1 = TestSupport.p1
    let p2 = TestSupport.p2
    
    let p1HandBefore = s.playerZone(p1).hand.map(\.id)
    let p2HandBefore = s.playerZone(p2).hand.map(\.id)
    let p1DeckBefore = s.playerZone(p1).deck.count
    let p2DeckBefore = s.playerZone(p2).deck.count
    let p1DiscardBefore = s.playerZone(p1).discard.count
    let p2DiscardBefore = s.playerZone(p2).discard.count
    
    let c1 = s.playerZone(p1).hand[0].id
    let c2 = s.playerZone(p2).hand[0].id
    
    s = Engine.reduce(state: s, intent: .selectCard(player: p1, card: c1)).state
    let t2 = Engine.reduce(state: s, intent: .selectCard(player: p2, card: c2))
    let sAfter = t2.state
    
    // Hands should end up same size (play 1, draw 1)
    #expect(sAfter.playerZone(p1).hand.count == 5)
    #expect(sAfter.playerZone(p2).hand.count == 5)
    
    // Deck decremented by 1 each.
    #expect(sAfter.playerZone(p1).deck.count == p1DeckBefore - 1)
    #expect(sAfter.playerZone(p2).deck.count == p2DeckBefore - 1)
    
    // Discard incremented by 1 each.
    #expect(sAfter.playerZone(p1).discard.count == p1DiscardBefore + 1)
    #expect(sAfter.playerZone(p2).discard.count == p2DiscardBefore + 1)
    
    // Selected cards removed from hands.
    #expect(!sAfter.playerZone(p1).hand.map(\.id).contains(c1))
    #expect(!sAfter.playerZone(p2).hand.map(\.id).contains(c2))
    
    // At least one of the hands should have changed composition.
    #expect(sAfter.playerZone(p1).hand.map(\.id) != p1HandBefore || sAfter.playerZone(p2).hand.map(\.id) != p2HandBefore)
    
    // Phase should return to selecting unless match ended.
    switch sAfter.phase {
    case .selecting, .matchEnded:
        #expect(true)
    default:
        #expect(false)
    }
    
    // Effects should include discard + two draws (one each), and roundEnded unless matchEnded.
    let drawCount = t2.effects.filter { if case .draw = $0 { true } else { false } }.count
    #expect(drawCount == 2)
    
    #expect(t2.effects.contains(where: { if case .discard = $0 { true } else { false } }))
}

@Test
func round_resolution_awards_token_to_winner_based_on_winning_card_element() {
    // Build a deterministic state where we control the hands:
    var s = TestSupport.initialState(seed: 1, initialHandSize: 1)
    
    let p1 = TestSupport.p1
    let p2 = TestSupport.p2
    
    // Force hands: p1 Fire beats p2 Snow.
    var z1 = s.playerZone(p1)
    var z2 = s.playerZone(p2)
    
    z1.hand = [Card(id: "p1_fire", element: .fire, level: 1)]
    z2.hand = [Card(id: "p2_snow", element: .snow, level: 10)]
    s.zones[p1] = z1
    s.zones[p2] = z2
    
    s = Engine.reduce(state: s, intent: .selectCard(player: p1, card: "p1_fire")).state
    let t2 = Engine.reduce(state: s, intent: .selectCard(player: p2, card: "p2_snow"))
    
    let sAfter = t2.state
    let p1Tokens = sAfter.playerZone(p1).tokens
    let p2Tokens = sAfter.playerZone(p2).tokens
    
    #expect(p1Tokens.counts[.fire] == 1)
    #expect(p2Tokens.counts.isEmpty)
    
    // Effect should include awardToken for p1 with the winning card snapshot.
    #expect(t2.effects.contains(where: { eff in
        if case let .awardToken(player, award) = eff {
            return player == p1 && award.element == .fire && award.cardId == "p1_fire"
        }
        return false
    }))
}

@Test
func round_resolution_tie_awards_no_token() {
    var s = TestSupport.initialState(seed: 1, initialHandSize: 1)
    
    let p1 = TestSupport.p1
    let p2 = TestSupport.p2
    
    // Tie: same element, same power.
    var z1 = s.playerZone(p1)
    var z2 = s.playerZone(p2)
    z1.hand = [Card(id: "p1_fire", element: .fire, level: 5)]
    z2.hand = [Card(id: "p2_fire", element: .fire, level: 5)]
    s.zones[p1] = z1
    s.zones[p2] = z2
    
    s = Engine.reduce(state: s, intent: .selectCard(player: p1, card: "p1_fire")).state
    let t2 = Engine.reduce(state: s, intent: .selectCard(player: p2, card: "p2_fire"))
    
    let sAfter = t2.state
    #expect(sAfter.playerZone(p1).tokens.awards.isEmpty)
    #expect(sAfter.playerZone(p2).tokens.awards.isEmpty)
    
    #expect(!t2.effects.contains(where: { if case .awardToken = $0 { true } else { false } }))
}
