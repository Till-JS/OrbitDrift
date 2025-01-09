import SpriteKit

class Asteroid: SKShapeNode {
    init(size: CGSize) {
        super.init()
        
        let path = CGMutablePath()
        let points = generateAsteroidPoints(size: size)
        
        path.move(to: points[0])
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        path.closeSubpath()
        
        self.path = path
        self.fillColor = .gray
        self.strokeColor = .darkGray
        self.lineWidth = 2.0
        
        // Physik-Körper für Kollisionserkennung
        self.physicsBody = SKPhysicsBody(polygonFrom: path)
        self.physicsBody?.categoryBitMask = PhysicsCategory.asteroid
        self.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.bullet
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.isDynamic = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func generateAsteroidPoints(size: CGSize) -> [CGPoint] {
        let numberOfPoints = 8
        var points: [CGPoint] = []
        let radius = min(size.width, size.height) / 2
        
        for i in 0..<numberOfPoints {
            let angle = (CGFloat(i) / CGFloat(numberOfPoints)) * 2 * .pi
            let randomRadius = radius * CGFloat.random(in: 0.7...1.3)
            let x = cos(angle) * randomRadius
            let y = sin(angle) * randomRadius
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
}
