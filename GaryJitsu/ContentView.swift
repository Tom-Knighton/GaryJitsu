//
//  ContentView.swift
//  GaryJitsu
//
//  Created by Tom Knighton on 23/02/2026.
//

import SwiftUI
import JitsuCore
import JitsuMatch
import JitsuGame

struct LocalGameRootView: View {
    @State private var coordinator: MatchCoordinator?
    
    var body: some View {
        Group {
            if let coordinator {
                GameView(coordinator: coordinator)
            } else {
                ProgressView()
                    .task {
                        let cfg = TestSupport.makeConfig(seed: 999, initialHandSize: 5)
                        let initial = Engine.makeInitialState(config: cfg).state
                        
                        let built = await LocalMatchFactory.build(
                            initialState: initial,
                            p1: TestSupport.p1,
                            p2: TestSupport.p2
                        )

                        coordinator = MatchCoordinator(
                            localPlayer: TestSupport.p1,
                            session: built.p1
                        )
                    }
            }
        }
    }
}
