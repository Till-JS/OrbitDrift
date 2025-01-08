import SpriteKit
import WatchKit

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
    private var playerShip: SKSpriteNode?          // Das Raumschiff-Sprite
    private var lastUpdateTime: TimeInterval = 0    // Zeitpunkt des letzten Updates
    private var lastCrownValue: Double = 0.5       // Letzte Position der Digital Crown
    private var currentPlayerY: CGFloat = 0        // Aktuelle vertikale Position des Schiffs
    
    /// Asteroiden-bezogene Eigenschaften
    private var lastAsteroidSpawn: TimeInterval = 0         // Zeitpunkt des letzten Asteroiden-Spawns
    private let asteroidSpawnInterval: TimeInterval = 2.0   // Zeitintervall zwischen Asteroiden
    private let asteroidSpeed: CGFloat = 100.0             // Geschwindigkeit der Asteroiden
    
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
        playerShip = SKSpriteNode(color: .cyan, size: CGSize(width: 15, height: 15))
        if let ship = playerShip {
            // Positioniere das Schiff
            currentPlayerY = frame.height / 2
            ship.position = CGPoint(x: frame.width * 0.2, y: currentPlayerY)
            
            // Konfiguriere Physik-Körper für Kollisionserkennung
            ship.physicsBody = SKPhysicsBody(rectangleOf: ship.size)
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
        guard let value = notification.userInfo?["value"] as? Double else { return }
        
        if let ship = playerShip {
            // Berechne neue vertikale Position basierend auf Crown-Rotation
            let newY = value * frame.height
            currentPlayerY = newY
            ship.position.y = currentPlayerY
        }
    }
    
    // MARK: - Update Loop
    
    /// Wird regelmäßig aufgerufen, um das Spiel zu aktualisieren
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            lastAsteroidSpawn = currentTime
            return
        }
        
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Spawn new asteroids
        if currentTime - lastAsteroidSpawn > asteroidSpawnInterval {
            spawnAsteroid()
            lastAsteroidSpawn = currentTime
        }
        
        // Update asteroid positions
        updateAsteroids(deltaTime)
        
        // Update score
        if GameManager.shared.isPlaying {
            GameManager.shared.addScore(1)
            updateScoreDisplay()
        }
    }
    
    // MARK: - Asteroiden Verwaltung
    
    /// Erstellt einen neuen Asteroiden
    private func spawnAsteroid() {
        let asteroid = Asteroid(size: CGSize(width: 20, height: 20))
        
        // Zufällige Y-Position
        let randomY = CGFloat.random(in: 0...frame.height)
        asteroid.position = CGPoint(x: frame.width + asteroid.size.width, y: randomY)
        
        // Zufällige Rotation
        asteroid.zRotation = CGFloat.random(in: 0...(2 * .pi))
        
        // Name für spätere Identifizierung
        asteroid.name = "asteroid"
        
        addChild(asteroid)
    }
    
    /// Aktualisiert die Positionen der Asteroiden
    private func updateAsteroids(_ deltaTime: TimeInterval) {
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
            
            // Change color based on remaining lives
            switch GameManager.shared.lives {
            case 3:
                ship.color = .gray  // First hit: change to gray
            case 2:
                ship.color = .red   // Second hit: change to red
            default:
                if GameManager.shared.handleCollision() {
                    showGameOver()
                }
            }
            
            // Handle collision in GameManager
            if GameManager.shared.handleCollision() {
                showGameOver()
            }
        }
    }
    
    // MARK: - Game Over
    
    /// Zeigt das Game Over-Menü an
    private func showGameOver() {
        let gameOverLabel = SKLabelNode(fontNamed: "Helvetica")
        gameOverLabel.text = "Game Over!"
        gameOverLabel.fontSize = 20
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(gameOverLabel)
        
        let scoreLabel = SKLabelNode(fontNamed: "Helvetica")
        scoreLabel.text = "Score: \(GameManager.shared.score)"
        scoreLabel.fontSize = 16
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.midY - 25)
        addChild(scoreLabel)
        
        let restartLabel = SKLabelNode(fontNamed: "Helvetica")
        restartLabel.text = "Tap to restart"
        restartLabel.fontSize = 14
        restartLabel.position = CGPoint(x: frame.midX, y: frame.midY - 50)
        addChild(restartLabel)
        
        // Stop spawning asteroids
        isPaused = true
    }
}
