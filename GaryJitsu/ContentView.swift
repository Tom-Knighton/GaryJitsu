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
    private var bundleLoader = BundledCardCatalogLoader(bundle: .main)
    
    var body: some View {
        Group {
            if let coordinator {
                GameView(coordinator: coordinator)
            } else {
                ProgressView()
                    .task {
                        do {
                            let catalog = try bundleLoader.loadCatalog()
                            let cfg = try MatchDataBuilder.makeLocalMatch(players: [TestSupport.p1, TestSupport.p2], seed: 999, catalog: catalog)
                            let initial = Engine.makeInitialState(config: cfg).state
                            
                            let transition = await LocalMatchFactory.build(
                                initialState: initial,
                                p1: TestSupport.p1,
                                p2: TestSupport.p2
                            )
                            
                            coordinator = MatchCoordinator(
                                localPlayer: TestSupport.p1,
                                matchData: cfg,
                                session: transition.p1
                            )
                        } catch {
                            print(error)
                        }
                    }
            }
        }
    }
}

#Preview(traits: .landscapeLeft) {
    LocalGameRootView()
}
