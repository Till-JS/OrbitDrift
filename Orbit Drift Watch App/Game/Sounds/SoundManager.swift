import AVFoundation

/// Verwaltet die Sound-Effekte im Spiel
class SoundManager {
    static let shared = SoundManager()
    
    private var shootSound: AVAudioPlayer?
    private var gameOverSound: AVAudioPlayer?
    
    private init() {
        setupSounds()
    }
    
    private func setupSounds() {
        // Erstelle kurzen Laser-Sound für das Schießen
        let shootSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        
        let shootDuration: TimeInterval = 0.1
        let shootFrequency: Double = 880.0 // A5 Note
        
        if let shootData = createBeepSound(frequency: shootFrequency, 
                                         duration: shootDuration, 
                                         settings: shootSettings) {
            shootSound = try? AVAudioPlayer(data: shootData)
            shootSound?.prepareToPlay()
        }
        
        // Erstelle Game Over Sound (tieferer, längerer Ton)
        let gameOverSettings = shootSettings
        let gameOverDuration: TimeInterval = 0.5
        let gameOverFrequency: Double = 220.0 // A3 Note
        
        if let gameOverData = createBeepSound(frequency: gameOverFrequency, 
                                            duration: gameOverDuration, 
                                            settings: gameOverSettings) {
            gameOverSound = try? AVAudioPlayer(data: gameOverData)
            gameOverSound?.prepareToPlay()
        }
    }
    
    private func createBeepSound(frequency: Double, duration: TimeInterval, settings: [String: Any]) -> Data? {
        let sampleRate = settings[AVSampleRateKey] as! Double
        let samplesCount = Int(sampleRate * duration)
        var samples = [Int16]()
        
        for i in 0..<samplesCount {
            let t = Double(i) / sampleRate
            let amplitude: Double = 0.25
            let sample = Int16(amplitude * 32767.0 * sin(2.0 * .pi * frequency * t))
            samples.append(sample)
        }
        
        return Data(bytes: samples, count: samples.count * 2)
    }
    
    /// Spielt den Schuss-Sound ab
    func playShootSound() {
        shootSound?.currentTime = 0
        shootSound?.play()
    }
    
    /// Spielt den Game Over Sound ab
    func playGameOverSound() {
        gameOverSound?.currentTime = 0
        gameOverSound?.play()
    }
}
