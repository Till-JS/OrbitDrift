//
//  GameScene.swift
//  Orbit Drift Watch App
//

import SpriteKit
import WatchKit
import SwiftUI

/// Definiert die verschiedenen Physik-Kategorien für Kollisionserkennung
struct PhysicsCategory {
    static let none      : UInt32 = 0         // Keine Kategorie
    static let player    : UInt32 = 0b1       // Spielerschiff (Bit 1)
    static let asteroid  : UInt32 = 0b10      // Asteroiden (Bit 2)
    static let bullet    : UInt32 = 0b100     // Schüsse (Bit 3)
    static let heart     : UInt32 = 0b1000    // Herz Power-Up (Bit 4)
}

/// Die Hauptspielszene, die das gesamte Gameplay verwaltet
class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Properties
    
    /// Spieler-bezogene Eigenschaften
    private var playerShip: SKShapeNode?          // Das Raumschiff-Sprite
    private var lastUpdateTime: TimeInterval = 0   // Zeitpunkt des letzten Updates
    private var currentPlayerY: CGFloat = 0       // Aktuelle vertikale Position des Schiffs
    private var lastCrownValue: Double = 0.5      // Letzte Position der Digital Crown
    private let playerXPosition: CGFloat = 0.15   // Horizontale Position des Spielers
    
    /// Asteroiden-bezogene Eigenschaften
    private var lastAsteroidSpawn: TimeInterval = 0         // Zeitpunkt des letzten Asteroiden-Spawns
    private let baseAsteroidInterval: TimeInterval = 2.0    // Basis-Zeitintervall zwischen Asteroiden
    private let asteroidSpeed: CGFloat = 150.0             // Geschwindigkeit der Asteroiden
    
    /// Herz Power-Up Eigenschaften
    private var lastHeartSpawn: TimeInterval = 0           // Zeitpunkt des letzten Herz-Spawns
    private let baseHeartInterval: TimeInterval = 15.0     // Basis-Zeitintervall zwischen Herzen
    private let heartSpeed: CGFloat = 100.0               // Geschwindigkeit der Herzen
    
    /// Schuss-bezogene Eigenschaften
    private let bulletSpeed: CGFloat = 300.0             // Geschwindigkeit der Schüsse
    
    /// UI-Elemente
    private var scoreLabel: SKLabelNode?   // Label zur Anzeige des Punktestands
    public private(set) var canRestartGame: Bool = true // Verhindert zu schnelles Neustarten
    
    /// Berechnet das aktuelle Spawn-Intervall basierend auf dem Score
    private var currentAsteroidInterval: TimeInterval {
        let score = GameManager.shared.score
        // Reduziere das Intervall mit steigendem Score
        // Bei Score 1000 ist das Intervall bei etwa 0.5 Sekunden
        let interval = baseAsteroidInterval * (1.0 / (1.0 + Double(score) / 1000.0))
        return max(0.5, interval) // Minimum 0.5 Sekunden
    }
    
    /// Berechnet die Anzahl der gleichzeitig zu spawnenden Asteroiden
    private var currentAsteroidCount: Int {
        let score = GameManager.shared.score
        // Erhöhe die Anzahl mit steigendem Score
        // Bei Score 0: 1 Asteroid
        // Bei Score 500: 2 Asteroiden
        // Bei Score 1500: 3 Asteroiden
        // usw.
        return 1 + Int(Double(score) / 500.0)
    }
    
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
            lastAsteroidSpawn = currentTime
            lastHeartSpawn = currentTime
            return
        }
        
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Aktualisiere Schiffposition
        updatePlayerPosition(deltaTime)
        
        // Spawn new asteroids
        if currentTime - lastAsteroidSpawn > currentAsteroidInterval {
            for _ in 1...currentAsteroidCount {
                spawnAsteroid()
            }
            lastAsteroidSpawn = currentTime
        }
        
        // Spawn new heart power-up
        if currentTime - lastHeartSpawn > baseHeartInterval {
            if GameManager.shared.lives < 3 {  // Nur spawnen wenn Leben fehlen
                spawnHeart()
            }
            lastHeartSpawn = currentTime
        }
        
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
    
    /// Erstellt einen neuen Asteroiden
    private func spawnAsteroid() {
        let asteroid = Asteroid(size: CGSize(width: 20, height: 20))
        
        // Zufällige Y-Position
        let randomY = CGFloat.random(in: 0...frame.height)
        asteroid.position = CGPoint(x: frame.width * 1.5, y: randomY)  // Spawne weiter rechts außerhalb des Bildschirms
        
        // Zufällige Rotation
        asteroid.zRotation = CGFloat.random(in: 0...(2 * .pi))
        
        // Name für spätere Identifizierung
        asteroid.name = "asteroid"
        
        addChild(asteroid)
    }
    
    /// Aktualisiert die Positionen der Asteroiden
    private func updateAsteroids(_ deltaTime: TimeInterval) {
        // Keine Bewegung während Game Over
        guard GameManager.shared.isGameRunning else { return }
        
        enumerateChildNodes(withName: "asteroid") { node, _ in
            // Bewege Asteroid nach links
            node.position.x -= self.asteroidSpeed * CGFloat(deltaTime)
            
            // Rotiere Asteroid
            node.zRotation += CGFloat(deltaTime)
            
            // Entferne Asteroid wenn außerhalb des Bildschirms
            if node.position.x < -node.frame.width {
                node.removeFromParent()
            }
        }
    }
    
    // MARK: - Herz Power-Up Verwaltung
    
    /// Erstellt ein neues Herz Power-Up
    private func spawnHeart() {
        // Erstelle ein Herz-Symbol
        let heart = SKShapeNode(path: createHeartPath(size: 12))
        heart.fillColor = .red
        heart.strokeColor = .clear
        heart.name = "heart"
        
        // Setze Position am rechten Bildschirmrand mit zufälliger Höhe
        let randomY = CGFloat.random(in: 0...frame.height)
        heart.position = CGPoint(x: frame.width + 10, y: randomY)
        
        // Füge Physik hinzu
        heart.physicsBody = SKPhysicsBody(polygonFrom: heart.path!)
        heart.physicsBody?.categoryBitMask = PhysicsCategory.heart
        heart.physicsBody?.contactTestBitMask = PhysicsCategory.player
        heart.physicsBody?.collisionBitMask = 0
        heart.physicsBody?.affectedByGravity = false
        
        addChild(heart)
    }
    
    /// Erstellt einen Herz-Pfad
    private func createHeartPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        
        // Herz-Form
        path.move(to: CGPoint(x: size/2, y: size*0.25))
        path.addCurve(to: CGPoint(x: size, y: 0),
                     control1: CGPoint(x: size/2, y: 0),
                     control2: CGPoint(x: size*0.75, y: 0))
        path.addCurve(to: CGPoint(x: size/2, y: size),
                     control1: CGPoint(x: size, y: size*0.5),
                     control2: CGPoint(x: size/2, y: size*0.75))
        path.addCurve(to: CGPoint(x: 0, y: 0),
                     control1: CGPoint(x: size/2, y: size*0.75),
                     control2: CGPoint(x: 0, y: size*0.5))
        path.addCurve(to: CGPoint(x: size/2, y: size*0.25),
                     control1: CGPoint(x: size*0.25, y: 0),
                     control2: CGPoint(x: size/2, y: 0))
        
        return path
    }
    
    /// Aktualisiert die Positionen der Herzen
    private func updateHearts(_ deltaTime: TimeInterval) {
        enumerateChildNodes(withName: "heart") { node, _ in
            // Bewege nach links
            node.position.x -= self.heartSpeed * CGFloat(deltaTime)
            
            // Entferne wenn außerhalb des Bildschirms
            if node.position.x < -10 {
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
        
        switch collision {
        case PhysicsCategory.player | PhysicsCategory.asteroid:
            // Kollision zwischen Spieler und Asteroid
            handlePlayerAsteroidCollision(contact)
            print("Kollision erkannt!")
            
        case PhysicsCategory.bullet | PhysicsCategory.asteroid:
            // Kollision zwischen Schuss und Asteroid
            handleBulletAsteroidCollision(contact)
            
        case PhysicsCategory.player | PhysicsCategory.heart:
            // Kollision zwischen Spieler und Herz
            handlePlayerHeartCollision(contact)
            
        default:
            break
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
        
        // Erstelle Explosionseffekt
        if let position = asteroid?.position {
            createExplosion(at: position)
        }
        
        // Bonus-Punkte für zerstörten Asteroiden
        GameManager.shared.addScore(50)
        GameManager.shared.addDestroyedAsteroid()
        showBonusPoints(50)
        
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
        
        // Bonus-Punkte für gesammeltes Herz
        GameManager.shared.addScore(100)
        showBonusPoints(100)
        
        // Erstelle Sammel-Effekt
        if let position = heart?.position {
            createHeartCollectionEffect(at: position)
        }
        
        // Sound für gesammeltes Herz
        WKInterfaceDevice.current().play(.success)
        
        // Aktualisiere Schifffarbe
        updateShipColor()
    }
    
    /// Aktualisiert die Farbe des Schiffs basierend auf den verbleibenden Leben
    private func updateShipColor() {
        guard let ship = playerShip else { return }
        
        switch GameManager.shared.lives {
        case 3:
            ship.fillColor = .cyan    // Volle Leben - Cyan
        case 2:
            ship.fillColor = .yellow  // Erste Warnung - Gelb
        case 1:
            ship.fillColor = .orange  // Zweite Warnung - Orange
        default:
            ship.fillColor = .red     // Game Over - Rot
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
        // Score Label ausblenden
        scoreLabel?.isHidden = true
        
        // Verhindere sofortiges Neustarten
        canRestartGame = false
        
        // Spiele Game Over Sound
        WKInterfaceDevice.current().play(.failure)
        
        // Game Over Label
        let gameOverLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 20
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: frame.width / 2, y: frame.height - 60)
        gameOverLabel.name = "gameOverLabel"
        addChild(gameOverLabel)
        
        // Final Score Label
        let finalScoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        finalScoreLabel.text = "Score: \(GameManager.shared.score)"
        finalScoreLabel.fontSize = 22
        finalScoreLabel.position = CGPoint(x: frame.width / 2, y: frame.height - 90)
        finalScoreLabel.name = "finalScoreLabel"
        addChild(finalScoreLabel)
        
        // Highscores Label
        let highscoresLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        highscoresLabel.text = "Highscores"
        highscoresLabel.fontSize = 16
        highscoresLabel.fontColor = .cyan
        highscoresLabel.position = CGPoint(x: frame.width / 2, y: frame.height - 115)
        highscoresLabel.name = "highscoresLabel"
        addChild(highscoresLabel)
        
        // Highscores Liste
        let highscores = GameManager.shared.highscores
        
        // #1 - Größter Score
        if highscores.count > 0 {
            let scoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
            scoreLabel.text = "1. \(highscores[0])"
            scoreLabel.fontSize = 14
            scoreLabel.position = CGPoint(x: frame.width / 2, y: frame.height - 140)
            scoreLabel.name = "highscore0"
            addChild(scoreLabel)
        }
        
        // #2 & #3 - Nebeneinander
        if highscores.count > 1 {
            let score2Label = SKLabelNode(fontNamed: "Helvetica-Bold")
            score2Label.text = "2. \(highscores[1])"
            score2Label.fontSize = 13
            score2Label.position = CGPoint(x: frame.width / 3, y: frame.height - 157)
            score2Label.name = "highscore1"
            addChild(score2Label)
        }
        
        if highscores.count > 2 {
            let score3Label = SKLabelNode(fontNamed: "Helvetica-Bold")
            score3Label.text = "3. \(highscores[2])"
            score3Label.fontSize = 13
            score3Label.position = CGPoint(x: (frame.width * 2) / 3, y: frame.height - 157)
            score3Label.name = "highscore2"
            addChild(score3Label)
        }
        
        // #4, #5 & #6 - Nebeneinander und kleiner
        let y456Position = frame.height - 172
        if highscores.count > 3 {
            let score4Label = SKLabelNode(fontNamed: "Helvetica-Bold")
            score4Label.text = "4. \(highscores[3])"
            score4Label.fontSize = 11
            score4Label.position = CGPoint(x: frame.width / 4, y: y456Position)
            score4Label.name = "highscore3"
            addChild(score4Label)
        }
        
        if highscores.count > 4 {
            let score5Label = SKLabelNode(fontNamed: "Helvetica-Bold")
            score5Label.text = "5. \(highscores[4])"
            score5Label.fontSize = 11
            score5Label.position = CGPoint(x: frame.width / 2, y: y456Position)
            score5Label.name = "highscore4"
            addChild(score5Label)
        }
        
        if highscores.count > 5 {
            let score6Label = SKLabelNode(fontNamed: "Helvetica-Bold")
            score6Label.text = "6. \(highscores[5])"
            score6Label.fontSize = 11
            score6Label.position = CGPoint(x: (frame.width * 3) / 4, y: y456Position)
            score6Label.name = "highscore5"
            addChild(score6Label)
        }
        
        // #7, #8, #9 & #10 - Nebeneinander und noch kleiner
        let y7810Position = frame.height - 187
        if highscores.count > 6 {
            let score7Label = SKLabelNode(fontNamed: "Helvetica-Bold")
            score7Label.text = "7. \(highscores[6])"
            score7Label.fontSize = 9
            score7Label.position = CGPoint(x: frame.width / 5, y: y7810Position)
            score7Label.name = "highscore6"
            addChild(score7Label)
        }
        
        if highscores.count > 7 {
            let score8Label = SKLabelNode(fontNamed: "Helvetica-Bold")
            score8Label.text = "8. \(highscores[7])"
            score8Label.fontSize = 9
            score8Label.position = CGPoint(x: (frame.width * 2) / 5, y: y7810Position)
            score8Label.name = "highscore7"
            addChild(score8Label)
        }
        
        if highscores.count > 8 {
            let score9Label = SKLabelNode(fontNamed: "Helvetica-Bold")
            score9Label.text = "9. \(highscores[8])"
            score9Label.fontSize = 9
            score9Label.position = CGPoint(x: (frame.width * 3) / 5, y: y7810Position)
            score9Label.name = "highscore8"
            addChild(score9Label)
        }
        
        if highscores.count > 9 {
            let score10Label = SKLabelNode(fontNamed: "Helvetica-Bold")
            score10Label.text = "10. \(highscores[9])"
            score10Label.fontSize = 9
            score10Label.position = CGPoint(x: (frame.width * 4) / 5, y: y7810Position)
            score10Label.name = "highscore9"
            addChild(score10Label)
        }
        
        // Tap to Restart Label (nach 1 Sekunde anzeigen)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.canRestartGame = true
            let tapLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
            tapLabel.text = "Tap to Restart"
            tapLabel.fontSize = 12
            tapLabel.position = CGPoint(x: self.frame.width / 2, y: 20)
            tapLabel.name = "tapLabel"
            tapLabel.alpha = 0
            self.addChild(tapLabel)
            
            // Fade-In Animation
            let fadeIn = SKAction.fadeIn(withDuration: 0.5)
            tapLabel.run(fadeIn)
        }
    }
    
    /// Entfernt alle Game Over Elemente
    private func removeGameOverElements() {
        // Entferne alle Labels mit spezifischen Namen
        enumerateChildNodes(withName: "gameOverLabel") { node, _ in
            node.removeFromParent()
        }
        enumerateChildNodes(withName: "finalScoreLabel") { node, _ in
            node.removeFromParent()
        }
        enumerateChildNodes(withName: "highscoresLabel") { node, _ in
            node.removeFromParent()
        }
        enumerateChildNodes(withName: "tapLabel") { node, _ in
            node.removeFromParent()
        }
        // Entferne alle Highscore Labels
        for i in 0..<10 {
            enumerateChildNodes(withName: "highscore\(i)") { node, _ in
                node.removeFromParent()
            }
        }
        
        // Score Label wieder einblenden
        scoreLabel?.isHidden = false
    }
    
    /// Startet das Spiel neu
    func restartGame() {
        // Entferne Game Over Elemente
        removeGameOverElements()
        
        // Entferne alle Asteroiden
        enumerateChildNodes(withName: "asteroid") { node, _ in
            node.removeFromParent()
        }
        
        // Entferne alle Herzen
        enumerateChildNodes(withName: "heart") { node, _ in
            node.removeFromParent()
        }
        
        // Entferne alle Schüsse
        enumerateChildNodes(withName: "bullet") { node, _ in
            node.removeFromParent()
        }
        
        // Setze Schifffarbe zurück
        playerShip?.fillColor = .cyan
        
        // Starte neues Spiel
        GameManager.shared.startGame()
        
        // Setze Crown-Position zurück
        NotificationCenter.default.post(
            name: Notification.Name("CrownDidRotate"),
            object: nil,
            userInfo: ["value": 0.5]  // Zurück zur Mitte
        )
        
        // Aktualisiere Schifffarbe
        updateShipColor()
    }
}
