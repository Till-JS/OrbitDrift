// ContentView.swift
// Hauptansicht der Orbit Drift Watch App
//
// Diese View ist verantwortlich für:
// - Einrichtung und Anzeige der SpriteKit-Spielszene
// - Verarbeitung der Digital Crown Eingaben
// - Weiterleitung der Steuerungseingaben an die Spiellogik

import SwiftUI
import SpriteKit

/// Die Hauptansicht der App, die das Spiel enthält und die Steuerung verarbeitet
struct ContentView: View {
    /// Aktuelle Rotation der Digital Crown (0.0 bis 1.0)
    @State private var crownRotation: Double = 0.5  // Start in der Mitte
    
    /// Fokus-State für die Digital Crown
    @FocusState private var isFocused: Bool
    
    /// Controller für die Spielszene, verwaltet den Spielzustand
    @StateObject private var sceneController = GameSceneController()
    
    var body: some View {
        GeometryReader { geometry in
            // SpriteKit-Spielszene wird in SwiftUI eingebettet
            SpriteView(scene: sceneController.scene, preferredFramesPerSecond: 60)
                .ignoresSafeArea()  // Nutzt den gesamten verfügbaren Bildschirm
                .focusable()        // Ermöglicht Fokus für Digital Crown Eingaben
                .focused($isFocused)  // Bindet den Fokus-State
                .onTapGesture {
                    guard let gameScene = sceneController.scene as? GameScene else { return }
                    
                    // Wenn das Spiel läuft, schieße
                    if GameManager.shared.isGameRunning {
                        gameScene.shoot()
                        return
                    }
                    
                    // Wenn Game Over und Neustarten erlaubt ist
                    if gameScene.canRestartGame {
                        GameManager.shared.startGame()
                        gameScene.restartGame()
                    }
                }
                // Konfiguration der Digital Crown
                .digitalCrownRotation(
                    $crownRotation,     // Binding zur Rotationsvariable
                    from: 0,            // Minimaler Wert
                    through: 1,         // Maximaler Wert
                    by: 0.002,         // Schrittweite für präzise Steuerung
                    sensitivity: .low,  // Niedrigere Empfindlichkeit für bessere Kontrolle
                    isContinuous: true,  // Erlaubt kontinuierliche Rotation
                    isHapticFeedbackEnabled: false  // Deaktiviert Haptic Feedback
                )
                .onAppear {
                    // Setze initialen Fokus
                    isFocused = true
                    
                    // Setze initiale Crown-Position
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NotificationCenter.default.post(
                            name: Notification.Name("CrownDidRotate"),
                            object: nil,
                            userInfo: ["value": crownRotation]
                        )
                    }
                }
                // Benachrichtigt die Spielszene über Änderungen der Crown-Position
                .onChange(of: crownRotation) { _, newValue in
                    NotificationCenter.default.post(
                        name: Notification.Name("CrownDidRotate"),
                        object: nil,
                        userInfo: ["value": newValue]
                    )
                }
        }
    }
}

/// Controller-Klasse für die GameScene
class GameSceneController: ObservableObject {
    let scene: SKScene
    
    init() {
        // Hole die tatsächliche Bildschirmgröße
        let screenSize = WKInterfaceDevice.current().screenBounds.size
        
        // Erstelle die Scene mit der korrekten Größe
        let scene = GameScene(size: screenSize)
        scene.scaleMode = .aspectFill
        
        print("Creating scene with size: \(screenSize)")
        self.scene = scene
    }
}
