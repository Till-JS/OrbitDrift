import SpriteKit
import WatchKit

class GameOverManager {
    private weak var scene: SKScene?
    private var scoreLabel: SKLabelNode?
    private var canRestartGame: Bool = true
    
    init(scene: SKScene, scoreLabel: SKLabelNode?) {
        self.scene = scene
        self.scoreLabel = scoreLabel
    }
    
    func showGameOver() {
        guard let scene = scene else { return }
        
        // Score Label ausblenden
        scoreLabel?.isHidden = true
        
        // Verhindere sofortiges Neustarten
        canRestartGame = false
        
        // Spiele Game Over Sound
        WKInterfaceDevice.current().play(.failure)
        
        // Game Over Text
        let gameOverLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        gameOverLabel.name = "gameOverLabel"
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 20
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: scene.frame.width/2, y: scene.frame.height - 60)
        scene.addChild(gameOverLabel)
        
        // Aktueller Score
        let finalScoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        finalScoreLabel.name = "finalScoreLabel"
        finalScoreLabel.text = "Score: \(GameManager.shared.score)"
        finalScoreLabel.fontSize = 22
        finalScoreLabel.position = CGPoint(x: scene.frame.width/2, y: scene.frame.height - 90)
        scene.addChild(finalScoreLabel)
        
        // Highscore Text
        let highscoreTextLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        highscoreTextLabel.name = "highscoreTextLabel"
        highscoreTextLabel.text = "Highscores"
        highscoreTextLabel.fontSize = 16
        highscoreTextLabel.fontColor = .cyan
        highscoreTextLabel.position = CGPoint(x: scene.frame.width/2, y: scene.frame.height - 115)
        scene.addChild(highscoreTextLabel)
        
        // Highscores anzeigen
        let highscores = GameManager.shared.highscores
        
        // #1 - Größter Score
        if highscores.count > 0 {
            let score1Label = SKLabelNode(fontNamed: "Helvetica-Bold")
            score1Label.name = "score1Label"
            score1Label.text = "1. \(highscores[0])"
            score1Label.fontSize = 14
            score1Label.position = CGPoint(x: scene.frame.width/2, y: scene.frame.height - 140)
            scene.addChild(score1Label)
        }
        
        // #2 & #3 - Nebeneinander
        if highscores.count > 1 {
            let score2Label = SKLabelNode(fontNamed: "Helvetica-Bold")
            score2Label.name = "score2Label"
            score2Label.text = "2. \(highscores[1])"
            score2Label.fontSize = 13
            score2Label.position = CGPoint(x: scene.frame.width/3, y: scene.frame.height - 157)
            scene.addChild(score2Label)
        }
        
        if highscores.count > 2 {
            let score3Label = SKLabelNode(fontNamed: "Helvetica-Bold")
            score3Label.name = "score3Label"
            score3Label.text = "3. \(highscores[2])"
            score3Label.fontSize = 13
            score3Label.position = CGPoint(x: (scene.frame.width * 2)/3, y: scene.frame.height - 157)
            scene.addChild(score3Label)
        }
        
        // #4, #5 & #6 - Nebeneinander und kleiner
        let y456Position = scene.frame.height - 172
        if highscores.count > 3 {
            let score4Label = SKLabelNode(fontNamed: "Helvetica-Bold")
            score4Label.name = "score4Label"
            score4Label.text = "4. \(highscores[3])"
            score4Label.fontSize = 11
            score4Label.position = CGPoint(x: scene.frame.width/4, y: y456Position)
            scene.addChild(score4Label)
        }
        
        if highscores.count > 4 {
            let score5Label = SKLabelNode(fontNamed: "Helvetica-Bold")
            score5Label.name = "score5Label"
            score5Label.text = "5. \(highscores[4])"
            score5Label.fontSize = 11
            score5Label.position = CGPoint(x: scene.frame.width/2, y: y456Position)
            scene.addChild(score5Label)
        }
        
        if highscores.count > 5 {
            let score6Label = SKLabelNode(fontNamed: "Helvetica-Bold")
            score6Label.name = "score6Label"
            score6Label.text = "6. \(highscores[5])"
            score6Label.fontSize = 11
            score6Label.position = CGPoint(x: (scene.frame.width * 3)/4, y: y456Position)
            scene.addChild(score6Label)
        }
        
        // #7, #8 & #9 - Nebeneinander und noch kleiner
        let y7810Position = scene.frame.height - 187
        if highscores.count > 6 {
            let score7Label = SKLabelNode(fontNamed: "Helvetica-Bold")
            score7Label.name = "score7Label"
            score7Label.text = "7. \(highscores[6])"
            score7Label.fontSize = 9
            score7Label.position = CGPoint(x: scene.frame.width/5, y: y7810Position)
            scene.addChild(score7Label)
        }
        
        if highscores.count > 7 {
            let score8Label = SKLabelNode(fontNamed: "Helvetica-Bold")
            score8Label.name = "score8Label"
            score8Label.text = "8. \(highscores[7])"
            score8Label.fontSize = 9
            score8Label.position = CGPoint(x: (scene.frame.width * 2)/5, y: y7810Position)
            scene.addChild(score8Label)
        }
        
        if highscores.count > 8 {
            let score9Label = SKLabelNode(fontNamed: "Helvetica-Bold")
            score9Label.name = "score9Label"
            score9Label.text = "9. \(highscores[8])"
            score9Label.fontSize = 9
            score9Label.position = CGPoint(x: (scene.frame.width * 3)/5, y: y7810Position)
            scene.addChild(score9Label)
        }
        
        if highscores.count > 9 {
            let score10Label = SKLabelNode(fontNamed: "Helvetica-Bold")
            score10Label.name = "score10Label"
            score10Label.text = "10. \(highscores[9])"
            score10Label.fontSize = 9
            score10Label.position = CGPoint(x: (scene.frame.width * 4)/5, y: y7810Position)
            scene.addChild(score10Label)
        }
        
        // Tap to Restart Label (nach 1 Sekunde anzeigen)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.canRestartGame = true
            let tapLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
            tapLabel.name = "tapToRestartLabel"
            tapLabel.text = "Tap to Restart"
            tapLabel.fontSize = 12
            tapLabel.position = CGPoint(x: scene.frame.width/2, y: y7810Position - 25)
            tapLabel.alpha = 0
            scene.addChild(tapLabel)
            
            // Fade-In Animation
            let fadeIn = SKAction.fadeIn(withDuration: 0.5)
            tapLabel.run(fadeIn)
        }
    }
    
    func removeGameOverElements() {
        guard let scene = scene else { return }
        
        // Entferne alle Labels mit spezifischen Namen
        let labelNames = [
            "gameOverLabel",
            "finalScoreLabel",
            "highscoreTextLabel",
            "score1Label",
            "score2Label",
            "score3Label",
            "score4Label",
            "score5Label",
            "score6Label",
            "score7Label",
            "score8Label",
            "score9Label",
            "score10Label",
            "tapToRestartLabel"
        ]
        
        for name in labelNames {
            scene.childNode(withName: name)?.removeFromParent()
        }
        
        // Score Label wieder anzeigen
        scoreLabel?.isHidden = false
    }
    
    var isRestartAllowed: Bool {
        return canRestartGame
    }
    
    func restartGame() {
        guard let scene = scene else { return }
        
        // Entferne Game Over Elemente
        removeGameOverElements()
        
        // Entferne alle Spielobjekte
        scene.enumerateChildNodes(withName: "asteroid") { node, _ in
            node.removeFromParent()
        }
        scene.enumerateChildNodes(withName: "heart") { node, _ in
            node.removeFromParent()
        }
        scene.enumerateChildNodes(withName: "bullet") { node, _ in
            node.removeFromParent()
        }
        
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
