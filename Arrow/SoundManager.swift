import Foundation
import AVFoundation
import UIKit
import AudioToolbox

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    var audioEffectsEnabled: Bool = Defaults.AudioEffectsEnabled
    var hapticFeedbackEnabled: Bool = Defaults.HapticFeedbackEnabled
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    /// Play a system sound effect
    func playSound(_ soundName: String) {
        // Check if audio effects are enabled
        guard audioEffectsEnabled else { return }
        
        // Use system sounds for now - these don't require audio files
        switch soundName {
        case "hit":
            // "Lock"" sound - like a "thud"
            AudioServicesPlaySystemSound(1305)
        case "miss":
            // "Negative hack" sound - like an error
            AudioServicesPlaySystemSound(1053)
        case "release":
            // "Mail sent" for arrow release - like a swush
            AudioServicesPlaySystemSound(1303)
        default:
            break
        }
    }
    
    /// Play a haptic feedback
    func playHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        // Check if haptic feedback is enabled
        guard hapticFeedbackEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
