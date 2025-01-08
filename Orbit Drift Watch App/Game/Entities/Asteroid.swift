//
//  Asteroid.swift
//  Orbit Drift
//
//  Created by Till Schneider on 08.01.2025.
//
import SpriteKit

class Asteroid: SKSpriteNode {
    init(size: CGSize) {
        super.init(texture: nil, color: .gray, size: size)
        setupPhysics()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPhysics() {
        self.physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
        self.physicsBody?.categoryBitMask = PhysicsCategory.asteroid
        self.physicsBody?.contactTestBitMask = PhysicsCategory.player
        self.physicsBody?.collisionBitMask = 0  // Keine physikalische Kollision
        self.physicsBody?.isDynamic = true
    }
}
