//
//  GameScene.swift
//  Orbit Drift Watch App
//

import SpriteKit
import WatchKit
import SwiftUI

/// Die Hauptspielszene, die das gesamte Gameplay verwaltet
class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Properties
    
    /// Spieler-bezogene Eigenschaften
    private var playerShip: SKShapeNode?          // Das Raumschiff-Sprite
    private var lastUpdateTime: TimeInterval = 0   // Zeitpunkt des letzten Updates
    private var currentPlayerY: CGFloat = 0       // Aktuelle vertikale Position des Schiffs
    private var lastCrownValue: Double = 0.5      // Letzte Position der Digital Crown
    private let playerXPosition: CGFloat = 0.15   // Horizontale Position des Spielers
    private var shieldActive: Bool = false        // Status des Schutzschilds
    private var shieldNode: SKShapeNode?          // Visueller Schutzschild
    
    /// UI-Elemente
    private var scoreLabel: SKLabelNode?   // Label zur Anzeige des Punktestands
    private var gameOverManager: GameOverManager?
    private var spawnManager: SpawnManager?
    
    /// Schuss-bezogene Eigenschaften
    private let bulletSpeed: CGFloat = 300.0             // Geschwindigkeit der Schüsse
    
    // MARK: - Initialization
    
    override init(size: CGSize) {
        super.init(size: size)
        print("Initializing GameScene with size: \(size)")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Scene Lifecycle
    
    /// Wird aufgerufen, wenn die Szene geladen wird
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        // Physik-Engine Setup
        physicsWorld.contactDelegate = self    // Ermöglicht Kollisionserkennung
        physicsWorld.gravity = .zero           // Deaktiviert Schwerkraft
        
        // Setze Weltraum-Hintergrund
        backgroundColor = .black
        
        // Initialisiere Spielkomponenten
        setupUI()
        setupPlayer()
        setupCrownControl()
        
        // Initialize SpawnManager
        spawnManager = SpawnManager(scene: self)
        
        // Starte das Spiel automatisch
        GameManager.shared.startGame()
    }
    
    // MARK: - Setup Methods
    
    /// Richtet die UI-Elemente ein
    private func setupUI() {
        // Erstelle und positioniere das Score-Label
        scoreLabel = SKLabelNode(fontNamed: "Helvetica")
        if let label = scoreLabel {
            label.fontSize = 14
            label.horizontalAlignmentMode = .right
            label.verticalAlignmentMode = .bottom
            label.position = CGPoint(x: frame.width - 10, y: 10)
            label.text = "0"
            addChild(label)
        }
        
        // Initialisiere den GameOverManager
        gameOverManager = GameOverManager(scene: self, scoreLabel: scoreLabel)
    }
    
    /// Erstellt und konfiguriert das Spielerschiff
    private func setupPlayer() {
        // Erstelle ein dreieckiges Schiff
        let shipPath = CGMutablePath()
        let shipSize: CGFloat = 15.0
        
        // Dreieck-Pfad (nach rechts zeigend)
        shipPath.move(to: CGPoint(x: -shipSize/2, y: -shipSize/2))     // Unten links
        shipPath.addLine(to: CGPoint(x: shipSize/2, y: 0))             // Spitze rechts
        shipPath.addLine(to: CGPoint(x: -shipSize/2, y: shipSize/2))   // Oben links
        shipPath.closeSubpath()                                         // Zurück zum Start
        
        // Erstelle Shape Node mit dem Pfad
        let ship = SKShapeNode(path: shipPath)
        ship.fillColor = .cyan
        ship.strokeColor = .clear  // Kein Rand
        ship.lineWidth = 0
        
        playerShip = ship
        
        if let ship = playerShip {
            // Konfiguriere Physik-Körper für Kollisionserkennung
            ship.physicsBody = SKPhysicsBody(polygonFrom: shipPath)
            ship.physicsBody?.categoryBitMask = PhysicsCategory.player
            ship.physicsBody?.contactTestBitMask = PhysicsCategory.asteroid | PhysicsCategory.heart
            ship.physicsBody?.collisionBitMask = 0  // Keine physische Kollision
            ship.physicsBody?.isDynamic = true
            
            ship.zPosition = 10  // Stelle sicher, dass das Schiff über anderen Elementen liegt
            
            addChild(ship)
            print("Player setup")
        }
    }
    
    /// Richtet die Crown-Steuerung ein
    private func setupCrownControl() {
        // Registriere für Crown-Rotations-Benachrichtigungen
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCrownRotation(_:)),
            name: Notification.Name("CrownDidRotate"),
            object: nil
        )
        
        // Setze initiale Position
        currentPlayerY = frame.height * 0.5
        lastCrownValue = 0.5
        
        if let ship = playerShip {
            ship.position = CGPoint(x: frame.width * playerXPosition, y: currentPlayerY)
        }
    }
    
    // MARK: - Input Handling
    
    /// Verarbeitet Crown-Rotationen
    @objc private func handleCrownRotation(_ notification: Notification) {
        guard let value = notification.userInfo?["value"] as? Double,
              let ship = playerShip else { return }
        
        // Berechne die Grenzen für die Crown-Position
        let minY = ship.frame.height/2
        let maxY = frame.height - ship.frame.height/2
        
        // Normalisiere die Crown-Position auf die erlaubten Grenzen
        let normalizedValue = max(minY/frame.height, min((maxY/frame.height), value))
        lastCrownValue = normalizedValue
    }
    
    // MARK: - Update Loop
    
    /// Wird regelmäßig aufgerufen, um das Spiel zu aktualisieren
    override func update(_ currentTime: TimeInterval) {
        // Prüfe, ob das Spiel noch läuft
        guard GameManager.shared.isGameRunning else { return }
        
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }
        
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Update player position
        updatePlayerPosition(deltaTime)
        
        // Update spawn manager
        spawnManager?.update(currentTime)
        
        // Update asteroid positions
        updateAsteroids(deltaTime)
        
        // Update heart positions
        updateHearts(deltaTime)
        
        // Passiver Score-Anstieg (1 Punkt pro Frame)
        GameManager.shared.addScore(1)
        
        // Update score
        updateScoreDisplay()
    }
    
    /// Aktualisiert die Position des Spielerschiffs
    private func updatePlayerPosition(_ deltaTime: TimeInterval) {
        guard let ship = playerShip else { return }
        
        // Direkte Positionierung basierend auf Crown-Position
        currentPlayerY = frame.height * CGFloat(lastCrownValue)
        
        // Stelle sicher, dass wir innerhalb der Bildschirmgrenzen bleiben
        currentPlayerY = max(ship.frame.height/2, min(frame.height - ship.frame.height/2, currentPlayerY))
        
        // Aktualisiere die Schiffposition
        ship.position = CGPoint(x: frame.width * playerXPosition, y: currentPlayerY)
    }
    
    // MARK: - Asteroiden Verwaltung
    
    /// Aktualisiert die Positionen der Asteroiden
    private func updateAsteroids(_ deltaTime: TimeInterval) {
        // Keine Bewegung während Game Over
        guard GameManager.shared.isGameRunning else { return }
        
        enumerateChildNodes(withName: "asteroid") { node, _ in
            // Bewege den Asteroiden nach links
            node.position.x -= 150.0 * CGFloat(deltaTime)  // Feste Geschwindigkeit
            
            // Entferne Asteroiden, die den Bildschirm verlassen haben
            if node.position.x < -50 {
                node.removeFromParent()
            }
        }
    }
    
    // MARK: - Herz Power-Up Verwaltung
    
    /// Aktualisiert die Positionen der Herzen
    private func updateHearts(_ deltaTime: TimeInterval) {
        enumerateChildNodes(withName: "heart") { node, _ in
            // Bewege das Herz nach links
            node.position.x -= 100.0 * CGFloat(deltaTime)  // Feste Geschwindigkeit
            
            // Entferne Herzen, die den Bildschirm verlassen haben
            if node.position.x < -50 {
                node.removeFromParent()
            }
        }
    }
    
    // MARK: - Score Verwaltung
    
    /// Aktualisiert die Anzeige des Punktestands
    private func updateScoreDisplay() {
        scoreLabel?.text = "\(GameManager.shared.score)"
    }
    
    // MARK: - Kollisionserkennung
    
    /// Wird aufgerufen, wenn eine Kollision erkannt wird
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // Kollision zwischen Spieler und Asteroid
        if collision == (PhysicsCategory.player | PhysicsCategory.asteroid) {
            if shieldActive {
                handleShieldCollision(contact)
            } else {
                handlePlayerAsteroidCollision(contact)
            }
        }
        
        // Kollision zwischen Spieler und Herz
        else if collision == (PhysicsCategory.player | PhysicsCategory.heart) {
            handlePlayerHeartCollision(contact)
        }
        
        // Kollision zwischen Spieler und Schutzschild
        else if collision == (PhysicsCategory.player | PhysicsCategory.shield) {
            handleShieldPickup(contact)
        }
        
        // Kollision zwischen Schuss und Asteroid
        else if collision == (PhysicsCategory.bullet | PhysicsCategory.asteroid) {
            handleBulletAsteroidCollision(contact)
        }
    }
    
    /// Verarbeitet die Kollision zwischen Spieler und Asteroid
    private func handlePlayerAsteroidCollision(_ contact: SKPhysicsContact) {
        // Identifiziere den Asteroiden
        let asteroid = contact.bodyA.categoryBitMask == PhysicsCategory.asteroid ? contact.bodyA.node : contact.bodyB.node
        
        // Entferne den Asteroiden
        asteroid?.removeFromParent()
        
        // Reduziere Leben und prüfe auf Game Over
        if GameManager.shared.handleCollision() {
            // Game Over Sound
            WKInterfaceDevice.current().play(.failure)
            showGameOver()
        } else {
            // Treffer-Sound wenn noch nicht Game Over
            WKInterfaceDevice.current().play(.directionDown)
            // Visuelles Feedback
            if let ship = playerShip {
                let fadeOut = SKAction.fadeAlpha(to: 0.5, duration: 0.2)
                let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.2)
                ship.run(SKAction.sequence([fadeOut, fadeIn]))
            }
            // Aktualisiere Schifffarbe
            updateShipColor()
        }
    }
    
    /// Verarbeitet die Kollision zwischen Schuss und Asteroid
    private func handleBulletAsteroidCollision(_ contact: SKPhysicsContact) {
        // Identifiziere Schuss und Asteroid
        let bullet = contact.bodyA.categoryBitMask == PhysicsCategory.bullet ? contact.bodyA.node : contact.bodyB.node
        let asteroid = contact.bodyA.categoryBitMask == PhysicsCategory.asteroid ? contact.bodyA.node : contact.bodyB.node
        
        // Entferne beide Objekte
        bullet?.removeFromParent()
        asteroid?.removeFromParent()
        
        // Erstelle Explosion an der Position des Asteroiden
        if let position = asteroid?.position {
            createExplosion(at: position)
        }
        
        // Erhöhe den Punktestand
        GameManager.shared.addScore(100)
        
        // Bonus-Punkte für zerstörten Asteroiden
        GameManager.shared.addDestroyedAsteroid()
        showBonusPoints(100)
        
        // Sound für zerstörten Asteroiden
        WKInterfaceDevice.current().play(.directionUp)
    }
    
    /// Verarbeitet die Kollision zwischen Spieler und Herz
    private func handlePlayerHeartCollision(_ contact: SKPhysicsContact) {
        // Identifiziere das Herz
        let heart = contact.bodyA.categoryBitMask == PhysicsCategory.heart ? contact.bodyA.node : contact.bodyB.node
        
        // Entferne das Herz
        heart?.removeFromParent()
        
        // Füge ein Leben hinzu
        GameManager.shared.addLife()
        GameManager.shared.addCollectedHeart()
        
        // Erhöhe den Punktestand
        GameManager.shared.addScore(500)
        showBonusPoints(500)
        
        // Erstelle Sammel-Effekt
        if let position = heart?.position {
            createHeartCollectionEffect(at: position)
        }
        
        // Sound für gesammeltes Herz
        WKInterfaceDevice.current().play(.success)
        
        // Aktualisiere Schifffarbe
        updateShipColor()
    }
    
    private func handleShieldPickup(_ contact: SKPhysicsContact) {
        // Entferne das Shield-PowerUp
        let shield = contact.bodyA.categoryBitMask == PhysicsCategory.shield ? contact.bodyA.node : contact.bodyB.node
        shield?.removeFromParent()
        
        // Erhöhe den Punktestand
        GameManager.shared.addScore(250)
        showBonusPoints(250)
        
        // Aktiviere den Schutzschild nur wenn keiner aktiv ist
        if !shieldActive {
            activateShield()
        }
    }
    
    private func handleShieldCollision(_ contact: SKPhysicsContact) {
        // Entferne den Asteroiden
        let asteroid = contact.bodyA.categoryBitMask == PhysicsCategory.asteroid ? contact.bodyA.node : contact.bodyB.node
        asteroid?.removeFromParent()
        
        // Zerstöre den Schutzschild mit Animation
        if let shield = shieldNode {
            // Aufblitzen und dann verschwinden
            let flash = SKAction.sequence([
                SKAction.fadeAlpha(to: 1.0, duration: 0.1),
                SKAction.fadeAlpha(to: 0.7, duration: 0.1),
                SKAction.wait(forDuration: 0.1),
                SKAction.group([
                    SKAction.scale(to: 1.5, duration: 0.2),
                    SKAction.fadeOut(withDuration: 0.2)
                ]),
                SKAction.removeFromParent()
            ])
            shield.run(flash)
            shieldNode = nil
            shieldActive = false
        }
    }
    
    private func activateShield() {
        guard let player = playerShip else { return }
        
        // Erstelle den visuellen Schutzschild
        let shield = SKShapeNode(circleOfRadius: 20)
        shield.strokeColor = .cyan
        shield.lineWidth = 2
        shield.fillColor = .clear
        shield.alpha = 0.7
        shield.zPosition = 1
        
        // Füge einen subtilen Pulsiereffekt hinzu
        let scaleUp = SKAction.scale(to: 1.05, duration: 1.0)
        let scaleDown = SKAction.scale(to: 0.95, duration: 1.0)
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        shield.run(SKAction.repeatForever(pulse))
        
        player.addChild(shield)
        shieldNode = shield
        shieldActive = true
    }
    
    private func deactivateShield() {
        shieldNode?.removeFromParent()
        shieldNode = nil
        shieldActive = false
    }
    
    /// Aktualisiert die Farbe des Schiffs basierend auf den verbleibenden Leben
    private func updateShipColor() {
        guard let ship = playerShip else { return }
        
        // Setze die Grundfarbe auf Cyan
        ship.fillColor = .cyan
        
        // Wenn weniger als 2 Leben übrig sind, färbe orange
        if GameManager.shared.lives < 2 {
            ship.fillColor = .orange
        }
    }
    
    /// Erstellt einen Partikeleffekt für das Einsammeln eines Herzens
    private func createHeartCollectionEffect(at position: CGPoint) {
        for _ in 0..<8 {
            let particle = SKShapeNode(circleOfRadius: 2)
            particle.fillColor = .red
            particle.strokeColor = .clear
            particle.position = position
            addChild(particle)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 10...20)
            let duration = TimeInterval.random(in: 0.2...0.4)
            
            let move = SKAction.move(to: CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            ), duration: duration)
            let fade = SKAction.fadeOut(withDuration: duration)
            let group = SKAction.group([move, fade])
            let remove = SKAction.removeFromParent()
            
            particle.run(SKAction.sequence([group, remove]))
        }
    }
    
    /// Erstellt eine Explosionsanimation
    private func createExplosion(at position: CGPoint) {
        // Erstelle mehrere kleine Partikel
        for _ in 0..<12 {
            let particle = SKShapeNode(circleOfRadius: 3.5)
            particle.fillColor = .yellow
            particle.strokeColor = .clear
            particle.position = position
            addChild(particle)
            
            // Zufällige Richtung
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 15...30)
            let duration = TimeInterval.random(in: 0.1...0.2)
            
            // Bewegung und Verblassen
            let move = SKAction.move(to: CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            ), duration: duration)
            let fade = SKAction.fadeOut(withDuration: duration)
            let group = SKAction.group([move, fade])
            let remove = SKAction.removeFromParent()
            
            particle.run(SKAction.sequence([group, remove]))
        }
    }
    
    /// Zeigt eine Animation für Bonus-Punkte
    private func showBonusPoints(_ points: Int) {
        guard let scoreLabel = scoreLabel else { return }
        
        let bonusLabel = SKLabelNode(fontNamed: "Helvetica")
        bonusLabel.text = "+\(points)"
        bonusLabel.fontSize = 14
        bonusLabel.fontColor = .yellow
        bonusLabel.horizontalAlignmentMode = .right
        bonusLabel.verticalAlignmentMode = .bottom
        bonusLabel.position = CGPoint(x: scoreLabel.position.x - 40, y: scoreLabel.position.y)
        bonusLabel.alpha = 0
        addChild(bonusLabel)
        
        // Fade in, warte, fade out und entfernen
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let wait = SKAction.wait(forDuration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        
        bonusLabel.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
    }
    
    /// Schießt einen Schuss ab
    public func shoot() {
        guard let ship = playerShip,
              GameManager.shared.isGameRunning else { return }
        
        // Schuss-Sound sofort abspielen
        WKInterfaceDevice.current().play(.start)
        
        // Erstelle einen Schuss
        let bullet = SKShapeNode(circleOfRadius: 3)
        bullet.fillColor = .cyan
        bullet.strokeColor = .clear
        bullet.position = ship.position
        bullet.name = "bullet"
        
        // Füge Physik-Body hinzu
        bullet.physicsBody = SKPhysicsBody(circleOfRadius: 3)
        bullet.physicsBody?.categoryBitMask = PhysicsCategory.bullet
        bullet.physicsBody?.contactTestBitMask = PhysicsCategory.asteroid
        bullet.physicsBody?.collisionBitMask = 0
        bullet.physicsBody?.affectedByGravity = false
        
        addChild(bullet)
        
        // Bewege den Schuss nach rechts
        let moveAction = SKAction.moveBy(x: frame.width, y: 0, duration: frame.width / bulletSpeed)
        let removeAction = SKAction.removeFromParent()
        bullet.run(SKAction.sequence([moveAction, removeAction]))
    }
    
    // MARK: - Game Over
    
    /// Zeigt den Game Over Screen an
    private func showGameOver() {
        gameOverManager?.showGameOver()
    }
    
    /// Entfernt alle Game Over Elemente
    private func removeGameOverElements() {
        gameOverManager?.removeGameOverElements()
    }
    
    /// Überprüft, ob das Spiel neu gestartet werden kann
    var canRestartGame: Bool {
        return gameOverManager?.isRestartAllowed ?? true
    }
    
    public func restartGame() {
        gameOverManager?.restartGame()
        
        // Setze Schutzschild-Status zurück
        shieldActive = false
        shieldNode?.removeFromParent()
        shieldNode = nil
        
        // Aktualisiere die Schiffsfarbe
        updateShipColor()
    }
}
