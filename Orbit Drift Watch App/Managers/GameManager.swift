//
//  GameManager.swift
//  Orbit Drift Watch App
//
// Der GameManager ist die zentrale Verwaltungsklasse für den Spielzustand.
// Er verwaltet:
// - Spielstand (Score)
// - Spielzustand (laufend/beendet)
// - Highscore-System
// - Spielschwierigkeit

import Foundation

/// GameManager verwaltet den globalen Spielzustand
/// Implementiert als Singleton für globalen Zugriff
class GameManager {
    // MARK: - Singleton
    
    /// Shared instance für globalen Zugriff
    static let shared = GameManager()
    
    /// Private Initialisierung verhindert externe Instanziierung
    private init() {}
    
    // MARK: - Spielzustand
    
    /// Aktueller Punktestand des Spielers
    private(set) var score: Int = 0
    
    /// Bester jemals erreichter Punktestand
    private(set) var highScore: Int {
        get {
            // Lade Highscore aus UserDefaults
            UserDefaults.standard.integer(forKey: "HighScore")
        }
        set {
            // Speichere neuen Highscore
            UserDefaults.standard.set(newValue, forKey: "HighScore")
        }
    }
    
    /// Gibt an, ob das Spiel aktiv läuft
    private(set) var isGameRunning: Bool = false
    
    /// Aktuelle Spielschwierigkeit (erhöht sich mit dem Score)
    private(set) var difficulty: Double = 1.0
    
    // MARK: - Spielsteuerung
    
    /// Startet ein neues Spiel
    /// - Setzt Score auf 0
    /// - Setzt Schwierigkeit zurück
    /// - Aktiviert den Spielzustand
    func startGame() {
        score = 0
        difficulty = 1.0
        isGameRunning = true
    }
    
    /// Beendet das aktuelle Spiel
    /// - Aktualisiert den Highscore wenn nötig
    /// - Deaktiviert den Spielzustand
    func endGame() {
        if score > highScore {
            highScore = score
        }
        isGameRunning = false
    }
    
    /// Erhöht den Punktestand um den angegebenen Wert
    /// - Parameter points: Anzahl der hinzuzufügenden Punkte
    /// - Aktualisiert auch die Schwierigkeit basierend auf dem Score
    func addScore(_ points: Int = 1) {
        guard isGameRunning else { return }
        
        score += points
        updateDifficulty()
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
}
