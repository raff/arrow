import Foundation
import CoreMotion
import Combine

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    
    @Published var pitch: Double = 0.0  // Up/down tilt (elevation)
    @Published var roll: Double = 0.0   // Left/right tilt (windage)
    @Published var isStable: Bool = true // Whether motion is relatively stable
    
    // Calibration offset - set when user calibrates
    private var pitchOffset: Double = 0.0
    private var rollOffset: Double = 0.0
    
    // Sensitivity and dampening controls (persisted)
    @Published var angleSensitivity: Double = Defaults.AngleSensitivity {
        didSet {
            UserDefaults.standard.set(angleSensitivity, forKey: "angleSensitivity")
        }
    }
    @Published var dampening: Double = Defaults.Dampening {
        didSet {
            UserDefaults.standard.set(dampening, forKey: "dampening")
        }
    }
    
    // Internal state for smoothing
    private var smoothedPitch: Double = 0.0
    private var smoothedRoll: Double = 0.0
    
    // Stability detection
    private let stabilityThreshold: Double = 0.02 // Acceleration threshold for "stable" state
    private var recentAccelerations: [Double] = []
    private let stabilityWindowSize: Int = 10
    
    init() {
        // Load persisted settings
        if UserDefaults.standard.object(forKey: "angleSensitivity") != nil {
            angleSensitivity = UserDefaults.standard.double(forKey: "angleSensitivity")
        }
        if UserDefaults.standard.object(forKey: "dampening") != nil {
            dampening = UserDefaults.standard.double(forKey: "dampening")
        }
        
        startMotionUpdates()
    }
    
    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 Hz
        
        // Use reference frame appropriate for device held vertically in portrait
        motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            
            // When phone is held vertically in portrait orientation:
            // - Pitch: Rotating around X-axis (tilting top forward/back) -> affects elevation
            // - Roll: Rotating around Z-axis (tilting left/right) -> affects windage
            // - Yaw: Rotating around Y-axis (turning left/right while vertical) -> we can use this too
            
            // For a phone held vertically in portrait:
            // - motion.attitude.pitch = rotation around device X axis (left-right edge)
            //   Moving arm up = pitch increases (device tilts back)
            //   Moving arm down = pitch decreases (device tilts forward)
            // - motion.attitude.roll = rotation around device Y axis (top-bottom edge)  
            //   Moving arm left = roll decreases (device tilts left)
            //   Moving arm right = roll increases (device tilts right)
            
            // Convert raw attitude to degrees
            let rawPitch = motion.attitude.pitch * 180.0 / .pi
            let rawRoll = motion.attitude.roll * 180.0 / .pi
            
            // Apply low-pass filter for smoothing (dampening)
            self.smoothedPitch = self.smoothedPitch * (1.0 - self.dampening) + rawPitch * self.dampening
            self.smoothedRoll = self.smoothedRoll * (1.0 - self.dampening) + rawRoll * self.dampening
            
            // Apply calibration offset and sensitivity
            let calibratedPitch = (self.smoothedPitch - self.pitchOffset) * self.angleSensitivity
            let calibratedRoll = (self.smoothedRoll - self.rollOffset)
            
            // Update published values
            self.pitch = calibratedPitch
            self.roll = calibratedRoll
            
            // Track acceleration for stability detection
            let userAccel = motion.userAcceleration
            let accelMagnitude = sqrt(userAccel.x * userAccel.x + userAccel.y * userAccel.y + userAccel.z * userAccel.z)
            self.updateStability(acceleration: accelMagnitude)
        }
    }
    
    func calibrate() {
        // Set current phone angle as the zero point (center)
        pitchOffset = smoothedPitch
        rollOffset = smoothedRoll
        
        // Immediately center the cursor
        pitch = 0.0
        roll = 0.0
    }
    
    private func updateStability(acceleration: Double) {
        // Keep a rolling window of recent accelerations
        recentAccelerations.append(acceleration)
        if recentAccelerations.count > stabilityWindowSize {
            recentAccelerations.removeFirst()
        }
        
        // Device is stable if all recent accelerations are below threshold
        if recentAccelerations.count == stabilityWindowSize {
            let allStable = recentAccelerations.allSatisfy { $0 < stabilityThreshold }
            isStable = allStable
        }
    }
    
    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    /// Reset all motion data
    func reset() {
        pitch = 0.0
        roll = 0.0
        smoothedPitch = 0.0
        smoothedRoll = 0.0
        pitchOffset = 0.0
        rollOffset = 0.0
        recentAccelerations.removeAll()
        isStable = true
    }
    
    deinit {
        stopMotionUpdates()
    }
}

// MARK: - Motion Processing Notes
/*
 This MotionManager uses phone angle (attitude) for aiming control:
 
 **Expected Usage:**
 - Hold the phone vertically in portrait orientation
 - Tap Calibrate to center the cursor at your current phone angle
 - Tilt the phone up/down to move the cursor up/down (elevation)
 - Tilt the phone left/right to move the cursor left/right (windage)
 
 **Technical Implementation:**
 
 1. **Reference Frame**: Uses .xArbitraryCorrectedZVertical
    - Designed for devices held vertically
    - Z-axis points up (opposite to gravity)
    - Provides stable reference for vertical device usage
 
 2. **Attitude (CMAttitude)**: Phone angle is the primary control
    - Pitch: Rotation around X-axis (tilting phone forward/back) → elevation
    - Roll: Rotation around Y-axis (tilting phone left/right) → windage
    - Smoothed with a low-pass filter to reduce jitter
 
 3. **Calibration**: Sets the zero point
    - Records the current phone angle as the center position
    - All subsequent angles are relative to this calibration point
    - Allows you to calibrate from any comfortable position
 
 4. **Sensitivity**: Adjustable angle-to-cursor mapping
    - Higher sensitivity = small angle changes move cursor more
    - Lower sensitivity = requires larger angle changes
    - Default 2.0x for comfortable control
 
 5. **Dampening**: Low-pass filter for smoothness
    - Reduces jitter and sudden movements
    - Lower dampening = smoother but slower response
    - Higher dampening = more responsive but potentially jittery
    - Default 0.15 (15% new value, 85% old value per frame)
 
 The combination provides:
 - Simple, predictable angle-based aiming
 - Smooth, stable cursor movement
 - Adjustable sensitivity and dampening for personal preference
 */
