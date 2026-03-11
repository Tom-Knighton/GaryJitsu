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
import JitsuMatch

public struct GameView: View {
    @Bindable private var coordinator: MatchCoordinator
    @State private var scene: GameScene

    public init(coordinator: MatchCoordinator) {
        self.coordinator = coordinator
        let initialScene = GameScene(
            size: CGSize(width: 960, height: 540),
            localPlayer: coordinator.localPlayer
        )
        
        _scene = State(initialValue: initialScene)
    }
    
    public var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .onGeometryChange(for: CGSize.self) { proxy in
                    proxy.size
                } action: { newSize in
                    updateSceneSize(for: newSize)
                }
                .onAppear {
                    coordinator.start()
                    
                    scene.onSelectCard = { [weak coordinator] cardId in
                        coordinator?.selectCard(cardId)
                        print("Selected Card")
                    }
                    
                    scene.render(state: coordinator.state, effects: coordinator.effects)
                }
                .onDisappear {
                    coordinator.stop()
                }
                .onChange(of: coordinator.state) { _, newValue in
                    scene.render(state: newValue, effects: coordinator.effects)
                }
        }
        .ignoresSafeArea()
    }
}

extension GameView {
    private func updateSceneSize(for viewSize: CGSize) {
        guard viewSize.width > 0, viewSize.height > 0 else { return }
        
        let newSize = Self.makeSceneSize(for: viewSize)
        
        guard scene.size != newSize else { return }
        
        scene.size = newSize
    }
    
    private static func makeSceneSize(for viewSize: CGSize) -> CGSize {
        let logicalWidth: CGFloat = 960
        let logicalHeight: CGFloat = 540
        
        var factor = viewSize.height / logicalHeight
        
        if viewSize.width / factor < logicalWidth {
            factor = viewSize.width / logicalWidth
        }
        
        return CGSize(
            width: viewSize.width / factor,
            height: viewSize.height / factor
        )
    }
}
