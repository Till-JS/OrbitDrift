import Foundation

/// Definiert die verschiedenen Physik-Kategorien für Kollisionserkennung
struct PhysicsCategory {
    static let none      : UInt32 = 0         // Keine Kategorie
    static let player    : UInt32 = 0b1       // Spielerschiff (Bit 1)
    static let asteroid  : UInt32 = 0b10      // Asteroiden (Bit 2)
    static let bullet    : UInt32 = 0b100     // Schüsse (Bit 3)
    static let heart     : UInt32 = 0b1000    // Herz Power-Up (Bit 4)
    static let shield    : UInt32 = 0b10000   // Schutzschild Power-Up (Bit 5)
}
