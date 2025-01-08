//
//  Asteroid.swift
//  Orbit Drift Watch App
//
//  Diese Klasse definiert das Verhalten und Aussehen der Asteroiden im Spiel.
//  Asteroiden sind die Haupthindernisse, denen der Spieler ausweichen muss.

import SpriteKit

/// Repräsentiert einen Asteroiden im Spiel
/// Erbt von SKSpriteNode für grundlegende Sprite-Funktionalität
class Asteroid: SKSpriteNode {
    
    /// Initialisiert einen neuen Asteroiden mit der angegebenen Größe
    /// - Parameter size: Die Größe des Asteroiden in Punkten
    init(size: CGSize) {
        super.init(texture: nil, color: .gray, size: size)
        setupPhysics()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Konfiguriert die Physik-Eigenschaften des Asteroiden
    /// - Erstellt einen kreisförmigen Physik-Körper
    /// - Setzt die Kollisionskategorien für Spieler-Interaktion
    private func setupPhysics() {
        self.physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
        self.physicsBody?.categoryBitMask = PhysicsCategory.asteroid     // Identifiziert den Körper als Asteroid
        self.physicsBody?.contactTestBitMask = PhysicsCategory.player    // Erkennt Kollisionen mit dem Spieler
        self.physicsBody?.collisionBitMask = 0                          // Keine physische Reaktion bei Kollision
        self.physicsBody?.isDynamic = true                              // Erlaubt Bewegung durch die Physik-Engine
    }
}
