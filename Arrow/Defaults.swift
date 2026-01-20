struct Defaults {
    // Arrow Properties
    static let ArrowSpeed: Double = 150 // fps
    static let ArrowWeight: Double = 400 // grains
    static let ArrowDiameter: Double = 7.0 // mm
    static let DrawLength: Double = 28.0 // inches
    static let DragCoefficient: Double = 0.55 // typical for arrows
    
    // Target Properties
    static let DistanceToTarget: Double = 59.0 // feet (18m - common indoor distance)
    static let TargetSize: Double = 40.0 // cm - target face size (40cm, 80cm, or 122cm)
    
    // Motion Control
    static let AngleSensitivity: Double = 1.0 // How much phone angle affects cursor (1.0 = normal, higher = more sensitive)
    static let Dampening: Double = 0.10 // Smoothing factor (0-1, lower = smoother/slower, higher = more responsive)
        
    // Audio & Haptic Preferences
    static let AudioEffectsEnabled: Bool = true // Enable/disable sound effects
    static let HapticFeedbackEnabled: Bool = true // Enable/disable haptic feedback
}
