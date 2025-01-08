//
//  ContentView.swift
//  Orbit Drift Watch App
//
//  Created by Till Schneider on 08.01.2025.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    @State private var crownRotation: Double = 0.5
    @StateObject private var sceneController = GameSceneController()
    
    var body: some View {
        SpriteView(scene: sceneController.scene)
            .ignoresSafeArea()
            .focusable()
            .digitalCrownRotation($crownRotation, from: 0, through: 1, by: 0.001, sensitivity: .medium)
            .onChange(of: crownRotation) { _, newValue in
                NotificationCenter.default.post(
                    name: Notification.Name("CrownDidRotate"),
                    object: nil,
                    userInfo: ["value": newValue]
                )
            }
    }
}

// Controller-Klasse für die GameScene
class GameSceneController: ObservableObject {
    let scene: SKScene
    
    init() {
        let scene = GameScene()
        scene.size = WKInterfaceDevice.current().screenBounds.size
        scene.scaleMode = .resizeFill
        self.scene = scene
    }
}
