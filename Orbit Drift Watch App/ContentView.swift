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
    @State private var crownRotation: Double = 0.5
    
    /// Controller für die Spielszene, verwaltet den Spielzustand
    @StateObject private var sceneController = GameSceneController()
    
    var body: some View {
        // SpriteKit-Spielszene wird in SwiftUI eingebettet
        SpriteView(scene: sceneController.scene)
            .ignoresSafeArea()  // Nutzt den gesamten verfügbaren Bildschirm
            .focusable()        // Ermöglicht Fokus für Digital Crown Eingaben
            // Konfiguration der Digital Crown
            .digitalCrownRotation(
                $crownRotation,     // Binding zur Rotationsvariable
                from: 0,            // Minimaler Wert
                through: 1,         // Maximaler Wert
                by: 0.001,         // Schrittweite für präzise Steuerung
                sensitivity: .medium // Mittlere Empfindlichkeit für optimale Kontrolle
            )
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

/// Controller-Klasse für die GameScene
/// Verantwortlich für die Initialisierung und Verwaltung der SpriteKit-Spielszene
class GameSceneController: ObservableObject {
    /// Die aktive Spielszene
    let scene: SKScene
    
    init() {
        let scene = GameScene()
        // Passt die Szene an die Bildschirmgröße der Apple Watch an
        scene.size = WKInterfaceDevice.current().screenBounds.size
        scene.scaleMode = .resizeFill
        self.scene = scene
    }
}
