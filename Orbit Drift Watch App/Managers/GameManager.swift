//
//  GameManager.swift
//  Orbit Drift
//
//  Created by Till Schneider on 08.01.2025.
//

import Foundation

class GameManager {
    static let shared = GameManager()
    
    var score: Int = 0
    var lives: Int = 3
    var isPlaying: Bool = false
    var gameSpeed: Float = 1.0
    var highScore: Int = UserDefaults.standard.integer(forKey: "highScore")
    
    private init() {}
    
    func startGame() {
        score = 0
        lives = 3
        isPlaying = true
        gameSpeed = 1.0
    }
    
    func handleCollision() -> Bool {
        lives -= 1
        if lives <= 0 {
            endGame()
            return true // Game Over
        }
        return false // Spiel geht weiter
    }
    
    func addScore(_ points: Int) {
        score += points
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "highScore")
        }
    }
    
    func endGame() {
        isPlaying = false
    }
}
