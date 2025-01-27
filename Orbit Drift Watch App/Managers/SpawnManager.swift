import SpriteKit

class SpawnManager {
    // MARK: - Properties
    private weak var scene: SKScene?
    
    // Asteroid Properties
    private var lastAsteroidSpawn: TimeInterval = 0
    private let baseAsteroidInterval: TimeInterval = 2.0
    private let asteroidSpeed: CGFloat = 150.0
    
    // Heart Properties
    private var lastHeartSpawn: TimeInterval = 0
    private let baseHeartInterval: TimeInterval = 15.0
    private let heartSpeed: CGFloat = 100.0
    private let heartSize: CGFloat = 15.0  // Größeres Herz
    
    // Shield Properties
    private var lastShieldSpawn: TimeInterval = 0
    private let baseShieldInterval: TimeInterval = 20.0
    private let shieldSpeed: CGFloat = 100.0
    private let shieldSize: CGFloat = 15.0
    
    // MARK: - Initialization
    init(scene: SKScene) {
        self.scene = scene
    }
    
    // MARK: - Computed Properties
    private var currentAsteroidInterval: TimeInterval {
        let score = GameManager.shared.score
        // Reduziere das Intervall mit steigendem Score
        let interval = baseAsteroidInterval * (1.0 / (1.0 + Double(score) / 1000.0))
        return max(0.5, interval) // Minimum 0.5 Sekunden
    }
    
    private var currentAsteroidCount: Int {
        let score = GameManager.shared.score
        // Erhöhe die Anzahl mit steigendem Score
        return 1 + Int(Double(score) / 500.0)
    }
    
    // MARK: - Update Methods
    func update(_ currentTime: TimeInterval) {
        guard let scene = scene else { return }
        
        // Spawn new asteroids
        if currentTime - lastAsteroidSpawn > currentAsteroidInterval {
            for _ in 0..<currentAsteroidCount {
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
        
        // Spawn new shield power-up
        if currentTime - lastShieldSpawn > baseShieldInterval {
            spawnShield()
            lastShieldSpawn = currentTime
        }
    }
    
    // MARK: - Spawn Methods
    private func spawnAsteroid() {
        guard let scene = scene else { return }
        
        let asteroid = Asteroid(size: CGSize(width: 20, height: 20))
        let randomY = CGFloat.random(in: 0...scene.frame.height)
        
        asteroid.position = CGPoint(x: scene.frame.width * 1.5, y: randomY)
        asteroid.name = "asteroid"
        
        // Zufällige Rotation
        asteroid.zRotation = CGFloat.random(in: 0...(2 * .pi))
        
        scene.addChild(asteroid)
    }
    
    private func spawnHeart() {
        guard let scene = scene else { return }
        
        // Erstelle ein Herz-Symbol
        let heart = SKShapeNode(path: createHeartPath(size: heartSize))
        heart.fillColor = .red
        heart.strokeColor = .clear
        heart.name = "heart"
        heart.zPosition = 1  // Stelle sicher, dass das Herz über anderen Objekten liegt
        
        // Setze Position am rechten Bildschirmrand mit zufälliger Höhe
        let randomY = CGFloat.random(in: heartSize...scene.frame.height-heartSize)
        heart.position = CGPoint(x: scene.frame.width + heartSize, y: randomY)
        
        // Füge Physik hinzu
        heart.physicsBody = SKPhysicsBody(polygonFrom: heart.path!)
        heart.physicsBody?.categoryBitMask = PhysicsCategory.heart
        heart.physicsBody?.contactTestBitMask = PhysicsCategory.player
        heart.physicsBody?.collisionBitMask = 0
        heart.physicsBody?.affectedByGravity = false
        heart.physicsBody?.isDynamic = true
        
        scene.addChild(heart)
    }
    
    private func spawnShield() {
        guard let scene = scene else { return }
        
        // Erstelle ein Schild-Symbol
        let shield = SKShapeNode(circleOfRadius: shieldSize)
        shield.fillColor = .cyan
        shield.strokeColor = .clear
        shield.name = "shield"
        shield.zPosition = 1
        
        // Setze Position am rechten Bildschirmrand mit zufälliger Höhe
        let randomY = CGFloat.random(in: shieldSize...scene.frame.height-shieldSize)
        shield.position = CGPoint(x: scene.frame.width + shieldSize, y: randomY)
        
        // Füge Physik hinzu
        shield.physicsBody = SKPhysicsBody(circleOfRadius: shieldSize)
        shield.physicsBody?.categoryBitMask = PhysicsCategory.shield  // Shield category
        shield.physicsBody?.contactTestBitMask = PhysicsCategory.player   // Kontakt mit Spieler
        shield.physicsBody?.collisionBitMask = 0
        
        // Bewegung nach links
        let moveLeft = SKAction.moveBy(x: -(scene.frame.width + 2 * shieldSize), y: 0, duration: TimeInterval(scene.frame.width / shieldSpeed))
        let remove = SKAction.removeFromParent()
        shield.run(SKAction.sequence([moveLeft, remove]))
        
        scene.addChild(shield)
    }
    
    /// Erstellt einen Herz-Pfad
    private func createHeartPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let scale: CGFloat = size / 12.0  // Skalierungsfaktor basierend auf der gewünschten Größe
        
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
        
        // Transformiere den Pfad zur gewünschten Größe
        var transform = CGAffineTransform(scaleX: scale, y: scale)
        return path.copy(using: &transform) ?? path
    }
    
    // MARK: - Reset
    func reset() {
        lastAsteroidSpawn = 0
        lastHeartSpawn = 0
        lastShieldSpawn = 0
    }
}
