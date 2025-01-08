import SpriteKit
import WatchKit
import UIKit

/// Definiert die verschiedenen Physik-Kategorien für Kollisionserkennung
struct PhysicsCategory {
    static let none      : UInt32 = 0         // Keine Kategorie
    static let player    : UInt32 = 0b1       // Spielerschiff (Bit 1)
    static let asteroid  : UInt32 = 0b10      // Asteroiden (Bit 2)
}

/// Die Hauptspielszene, die das gesamte Gameplay verwaltet
class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Properties
    
    /// Spieler-bezogene Eigenschaften
    private var playerShip: SKShapeNode?          // Das Raumschiff-Sprite
    private var lastUpdateTime: TimeInterval = 0    // Zeitpunkt des letzten Updates
    private var lastCrownValue: Double = 0.5       // Letzte Position der Digital Crown
    private var currentPlayerY: CGFloat = 0        // Aktuelle vertikale Position des Schiffs
    
    /// Asteroiden-bezogene Eigenschaften
    private var lastAsteroidSpawn: TimeInterval = 0         // Zeitpunkt des letzten Asteroiden-Spawns
    private let baseAsteroidInterval: TimeInterval = 2.0    // Basis-Zeitintervall zwischen Asteroiden
    private let asteroidSpeed: CGFloat = 150.0             // Geschwindigkeit der Asteroiden
    private let playerXPosition: CGFloat = 0.15            // Horizontale Position des Spielers
    
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
    
    /// UI-Elemente
    private var scoreLabel: SKLabelNode?   // Label zur Anzeige des Punktestands
    
    // MARK: - Scene Lifecycle
    
    /// Wird aufgerufen, wenn die Szene geladen wird
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        // Physik-Engine Setup
        physicsWorld.contactDelegate = self    // Ermöglicht Kollisionserkennung
        physicsWorld.gravity = .zero           // Deaktiviert Schwerkraft
        
        // Setze Weltraum-Hintergrund
        backgroundColor = .init(red: 0.04, green: 0.04, blue: 0.16, alpha: 1.0)
        print("Scene loaded with size: \(frame.size)")
        
        // Initialisiere Spielkomponenten
        setupUI()
        setupPlayer()
        setupCrownControl()
        
        // Setze initiale Position des Schiffs
        if let ship = playerShip {
            currentPlayerY = frame.height * 0.5
            ship.position = CGPoint(x: frame.width * playerXPosition, y: currentPlayerY)
            print("Initial ship position set to: \(ship.position)")
        }
        
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
            label.verticalAlignmentMode = .top
            label.position = CGPoint(x: frame.width - 10, y: frame.height - 10)
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
            // Setze initiale Position in der Mitte des Bildschirms
            currentPlayerY = frame.height * 0.5  // 50% der Bildschirmhöhe
            lastCrownValue = 0.5  // Setze Crown-Wert auf die Mitte
            ship.position = CGPoint(x: frame.width * playerXPosition, y: currentPlayerY)
            ship.zPosition = 10  // Stelle sicher, dass das Schiff über anderen Elementen liegt
            
            // Konfiguriere Physik-Körper für Kollisionserkennung
            ship.physicsBody = SKPhysicsBody(polygonFrom: shipPath)
            ship.physicsBody?.categoryBitMask = PhysicsCategory.player
            ship.physicsBody?.contactTestBitMask = PhysicsCategory.asteroid
            ship.physicsBody?.collisionBitMask = 0  // Keine physische Kollision
            ship.physicsBody?.isDynamic = true
            
            addChild(ship)
            print("Player setup at position: \(ship.position)")
        }
    }
    
    /// Richtet die Digital Crown Steuerung ein
    private func setupCrownControl() {
        // Setze initiale Crown-Position
        NotificationCenter.default.post(
            name: Notification.Name("CrownDidRotate"),
            object: nil,
            userInfo: ["value": 0.5]  // Starte in der Mitte
        )
        
        // Füge Observer hinzu
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCrownRotation),
            name: Notification.Name("CrownDidRotate"),
            object: nil
        )
    }
    
    // MARK: - Input Handling
    
    /// Verarbeitet die Rotationsbewegungen der Digital Crown
    @objc private func handleCrownRotation(_ notification: Notification) {
        // Keine Bewegung während Game Over
        guard GameManager.shared.isGameRunning else { return }
        
        guard let value = notification.userInfo?["value"] as? Double else { return }
        lastCrownValue = value  // Speichere den letzten Wert
        
        if let ship = playerShip {
            // Berechne neue vertikale Position basierend auf Crown-Rotation
            currentPlayerY = value * frame.height
            ship.position = CGPoint(x: frame.width * playerXPosition, y: currentPlayerY)
        }
    }
    
    // MARK: - Update Loop
    
    /// Wird regelmäßig aufgerufen, um das Spiel zu aktualisieren
    override func update(_ currentTime: TimeInterval) {
        // Prüfe, ob das Spiel noch läuft
        guard GameManager.shared.isGameRunning else { return }
        
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            lastAsteroidSpawn = currentTime
            return
        }
        
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Spawn new asteroids
        if currentTime - lastAsteroidSpawn > currentAsteroidInterval {
            for _ in 1...currentAsteroidCount {
                spawnAsteroid()
            }
            lastAsteroidSpawn = currentTime
        }
        
        // Update asteroid positions
        updateAsteroids(deltaTime)
        
        // Update score
        GameManager.shared.addScore(1)
        updateScoreDisplay()
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
    
    // MARK: - Score Verwaltung
    
    /// Aktualisiert die Anzeige des Punktestands
    private func updateScoreDisplay() {
        scoreLabel?.text = "\(GameManager.shared.score)"
    }
    
    // MARK: - Kollisionserkennung
    
    /// Wird aufgerufen, wenn eine Kollision erkannt wird
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if collision == PhysicsCategory.player | PhysicsCategory.asteroid {
            print("Kollision erkannt!")
            handleCollision()
        }
    }
    
    /// Verarbeitet die Kollision zwischen Spieler und Asteroid
    private func handleCollision() {
        if let ship = playerShip {
            // Vibration feedback
            WKInterfaceDevice.current().play(.notification)
            
            // Visuelles Feedback basierend auf verbleibenden Leben
            // Prüfe zuerst auf Game Over
            if GameManager.shared.handleCollision() {
                ship.fillColor = .red     // Game Over - Schiff wird rot
                showGameOver()
                return
            }
            
            // Wenn nicht Game Over, setze Farbe basierend auf verbleibenden Leben
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
            
            // Blink-Animation
            let fadeOut = SKAction.fadeAlpha(to: 0.5, duration: 0.2)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.2)
            ship.run(SKAction.sequence([fadeOut, fadeIn]))
        }
    }
    
    // MARK: - Game Over
    
    /// Zeigt das Game Over-Menü an
    private func showGameOver() {
        // Game Over Label
        let gameOverLabel = SKLabelNode(fontNamed: "Helvetica")
        gameOverLabel.text = "Game Over!"
        gameOverLabel.fontSize = 20
        gameOverLabel.position = CGPoint(x: frame.width / 2, y: frame.height / 2 + 30)
        gameOverLabel.name = "gameOverLabel"
        addChild(gameOverLabel)
        
        // Score Label
        let finalScoreLabel = SKLabelNode(fontNamed: "Helvetica")
        finalScoreLabel.text = "Score: \(GameManager.shared.score)"
        finalScoreLabel.fontSize = 16
        finalScoreLabel.position = CGPoint(x: frame.width / 2, y: frame.height / 2 + 10)
        finalScoreLabel.name = "gameOverLabel"
        addChild(finalScoreLabel)
        
        // Highscore Label
        let highscoreLabel = SKLabelNode(fontNamed: "Helvetica")
        highscoreLabel.text = "Best: \(GameManager.shared.highscore)"
        highscoreLabel.fontSize = 16
        highscoreLabel.position = CGPoint(x: frame.width / 2, y: frame.height / 2 - 10)
        highscoreLabel.name = "gameOverLabel"
        addChild(highscoreLabel)
        
        // New Highscore Indicator
        if GameManager.shared.score >= GameManager.shared.highscore {
            let newHighscoreLabel = SKLabelNode(fontNamed: "Helvetica")
            newHighscoreLabel.text = "New Best!"
            newHighscoreLabel.fontSize = 14
            newHighscoreLabel.fontColor = .yellow
            newHighscoreLabel.position = CGPoint(x: frame.width / 2, y: frame.height / 2 - 30)
            newHighscoreLabel.name = "gameOverLabel"
            addChild(newHighscoreLabel)
        }
        
        // Tap to Restart Label
        let tapLabel = SKLabelNode(fontNamed: "Helvetica")
        tapLabel.text = "Tap to Restart"
        tapLabel.fontSize = 16
        tapLabel.position = CGPoint(x: frame.width / 2, y: frame.height / 2 - 50)
        tapLabel.name = "tapLabel"
        addChild(tapLabel)
    }
    
    /// Startet ein neues Spiel
    func restartGame() {
        // Entferne Game Over Labels
        enumerateChildNodes(withName: "gameOverLabel") { node, _ in
            node.removeFromParent()
        }
        enumerateChildNodes(withName: "tapLabel") { node, _ in
            node.removeFromParent()
        }
        
        // Setze Spielerschiff zurück
        currentPlayerY = frame.height * 0.5  // Zurück zur Mitte
        playerShip?.position = CGPoint(x: frame.width * playerXPosition, y: currentPlayerY)
        playerShip?.fillColor = .cyan
        
        // Starte neues Spiel
        GameManager.shared.startGame()
        
        // Setze Crown-Position zurück
        NotificationCenter.default.post(
            name: Notification.Name("CrownDidRotate"),
            object: nil,
            userInfo: ["value": 0.5]  // Zurück zur Mitte
        )
    }
}
