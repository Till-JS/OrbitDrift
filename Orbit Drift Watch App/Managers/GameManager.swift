//
//  GameManager.swift
//  Orbit Drift Watch App
//
// Der GameManager ist die zentrale Verwaltungsklasse für den Spielzustand.
// Er verwaltet:
// - Spielstand (Score)
// - Leben des Spielers
// - Spielzustand (laufend/beendet)
// - Highscore-System
// - Spielschwierigkeit

import Foundation

/// Struktur für ein einzelnes Spielergebnis
struct GameScore: Codable {
    let score: Int
    let destroyedAsteroids: Int
    let collectedHearts: Int
}

/// Verwaltet den Spielzustand und die Spiellogik
class GameManager {
    /// Singleton-Instanz für globalen Zugriff
    static let shared = GameManager()
    
    // MARK: - Properties
    
    /// Aktuelle Punktzahl
    private(set) var score: Int = 0
    
    /// Aktueller Highscore
    private(set) var highscore: Int = UserDefaults.standard.integer(forKey: "highscore")
    
    /// Liste der Top 10 Highscores
    private(set) var highscores: [Int] = UserDefaults.standard.array(forKey: "highscores") as? [Int] ?? []
    
    /// Alle Spielergebnisse
    private(set) var allGames: [GameScore] = {
        if let data = UserDefaults.standard.data(forKey: "allGames"),
           let decoded = try? JSONDecoder().decode([GameScore].self, from: data) {
            return decoded
        }
        return []
    }()
    
    /// Anzahl der zerstörten Asteroiden in dieser Runde
    private(set) var destroyedAsteroids: Int = 0
    
    /// Anzahl der gesammelten Leben in dieser Runde
    private(set) var collectedHearts: Int = 0
    
    /// Anzahl der verbleibenden Leben
    private(set) var lives: Int = 3
    
    /// Gibt an, ob das Spiel läuft
    private(set) var isGameRunning: Bool = false
    
    /// Aktuelle Spielschwierigkeit (erhöht sich mit dem Score)
    private(set) var difficulty: Double = 1.0
    
    // MARK: - Game Control
    
    /// Startet ein neues Spiel
    /// - Setzt Score auf 0
    /// - Setzt Leben auf 3
    /// - Setzt Schwierigkeit zurück
    /// - Aktiviert den Spielzustand
    func startGame() {
        score = 0
        lives = 3
        difficulty = 1.0
        destroyedAsteroids = 0
        collectedHearts = 0
        isGameRunning = true
    }
    
    /// Fügt Punkte zum aktuellen Score hinzu
    /// - Parameter points: Anzahl der hinzuzufügenden Punkte
    /// - Aktualisiert auch die Schwierigkeit basierend auf dem Score
    func addScore(_ points: Int = 1) {
        guard isGameRunning else { return }
        
        score += points
        // Aktualisiere Highscore wenn nötig
        if score > highscore {
            highscore = score
            UserDefaults.standard.set(highscore, forKey: "highscore")
        }
        updateDifficulty()
    }
    
    /// Verarbeitet eine Kollision
    /// - Returns: True wenn Game Over, False wenn noch Leben übrig
    func handleCollision() -> Bool {
        guard isGameRunning else { return true }
        
        lives -= 1
        if lives <= 0 {
            endGame()
            return true
        }
        return false
    }
    
    /// Beendet das aktuelle Spiel
    /// - Aktualisiert den Highscore wenn nötig
    /// - Deaktiviert den Spielzustand
    func endGame() {
        if score > highscore {
            highscore = score
            UserDefaults.standard.set(highscore, forKey: "highscore")
        }
        
        // Füge aktuellen Score zu Highscores hinzu
        highscores.append(score)
        // Sortiere absteigend und behalte nur die Top 10
        highscores.sort(by: >)
        if highscores.count > 10 {
            highscores = Array(highscores.prefix(10))
        }
        // Speichere die aktualisierten Highscores
        UserDefaults.standard.set(highscores, forKey: "highscores")
        
        // Erstelle und speichere das Spielergebnis
        let gameScore = GameScore(
            score: score,
            destroyedAsteroids: destroyedAsteroids,
            collectedHearts: collectedHearts
        )
        allGames.append(gameScore)
        
        // Speichere alle Spiele
        if let encoded = try? JSONEncoder().encode(allGames) {
            UserDefaults.standard.set(encoded, forKey: "allGames")
        }
        
        isGameRunning = false
    }
    
    /// Fügt ein Leben hinzu, maximal bis zu 3 Leben
    func addLife() {
        guard isGameRunning, lives < 3 else { return }
        lives += 1
    }
    
    /// Registriert einen zerstörten Asteroiden
    func addDestroyedAsteroid() {
        destroyedAsteroids += 1
    }
    
    /// Registriert ein gesammeltes Herz
    func addCollectedHeart() {
        collectedHearts += 1
    }
    
    // MARK: - Hilfsfunktionen
    
    /// Aktualisiert die Spielschwierigkeit basierend auf dem aktuellen Score
    /// Die Schwierigkeit steigt logarithmisch mit dem Score
    private func updateDifficulty() {
        // Erhöhe Schwierigkeit alle 10 Punkte um 10%
        difficulty = 1.0 + (Double(score) / 10.0) * 0.1
    }
    
    /// Gibt die aktuelle Geschwindigkeit für neue Asteroiden zurück
    /// Basiert auf der Grundgeschwindigkeit und der aktuellen Schwierigkeit
    /// - Returns: Die berechnete Geschwindigkeit
    func getCurrentAsteroidSpeed() -> Double {
        let baseSpeed = 100.0
        return baseSpeed * difficulty
    }
    
    /// Gibt das aktuelle Zeitintervall zwischen Asteroiden-Spawns zurück
    /// Wird mit steigender Schwierigkeit kürzer
    /// - Returns: Zeitintervall in Sekunden
    func getCurrentSpawnInterval() -> TimeInterval {
        let baseInterval = 2.0
        return baseInterval / difficulty
    }
    
    /// Gibt die formatierten Top 10 Scores zurück
    func getFormattedTopScores() -> [(score: Int, date: String)] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        // Sortiere alle Spiele nach Punktzahl (absteigend)
        let sortedGames = allGames.sorted { $0.score > $1.score }
        
        // Nimm die Top 10 und formatiere sie
        return sortedGames.prefix(10).map { game in
            (score: game.score, date: dateFormatter.string(from: Date()))
        }
    }
    
    /// Gibt die Gesamtstatistik zurück
    func getTotalStats() -> (totalGames: Int, averageScore: Int, bestScore: Int) {
        let totalGames = allGames.count
        let averageScore = totalGames > 0 ? allGames.map { $0.score }.reduce(0, +) / totalGames : 0
        let bestScore = allGames.map { $0.score }.max() ?? 0
        
        return (totalGames: totalGames, averageScore: averageScore, bestScore: bestScore)
    }
    
    // MARK: - Initialization
    
    private init() {
        // Private Initialisierer für Singleton-Pattern
    }
}
