//
//  GameView.swift
//  JitsuGame
//
//  Created by Tom Knighton on 24/02/2026.
//

import SwiftUI
import SpriteKit
import Observation
import JitsuCore

public struct GameView: View {
    @Bindable private var coordinator: MatchCoordinator
    @State private var scene: GameScene
    
    public init(coordinator: MatchCoordinator) {
        self.coordinator = coordinator
        let scene = GameScene(localPlayer: coordinator.localPlayer)
        _scene = State(initialValue: scene)
    }
    
    public var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .onAppear {
                coordinator.start()
                
                scene.onSelectCard = { [weak coordinator] cardId in
                    coordinator?.selectCard(cardId)
                    print("Selected Card")
                }
                
                scene.render(state: coordinator.state)
            }
            .onDisappear {
                coordinator.stop()
            }
            .onChange(of: coordinator.state) { _, newValue in
                scene.render(state: newValue)
            }
    }
}
