import SwiftUI
import Combine
import AVFoundation
import MediaPlayer

// MARK: - Volume Button Monitor
class VolumeButtonMonitor: NSObject, ObservableObject {
    @Published var volumePressed = false
    private var lastVolume: Float = 0.5
    private var audioSession: AVAudioSession!
    private var volumeView: MPVolumeView?
    
    override init() {
        super.init()
        setupVolumeMonitor()
    }
    
    private func setupVolumeMonitor() {
        audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setActive(true)
        } catch {
            print("Error activating audio session: \(error)")
        }
        
        // Get initial volume
        lastVolume = audioSession.outputVolume
        
        // Observe volume changes
        audioSession.addObserver(self, forKeyPath: "outputVolume", options: [.new, .old], context: nil)
    }
    
    private func setVolume(_ volume: Float) {
        // Use MPVolumeView to set volume programmatically
        if volumeView == nil {
            volumeView = MPVolumeView(frame: .zero)
        }
        
        if let slider = volumeView?.subviews.first(where: { $0 is UISlider }) as? UISlider {
            slider.value = volume
            slider.sendActions(for: .valueChanged)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "outputVolume" {
            if let newVolume = change?[.newKey] as? Float {
                // Detect if volume changed (indicating button press)
                if newVolume > lastVolume {
                    DispatchQueue.main.async {
                        // Trigger the event
                        self.volumePressed = true
                        
                        // Reset volume back to previous value
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            self.setVolume(self.lastVolume)
                        }
                        
                        // Reset the pressed flag after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.volumePressed = false
                        }
                    }
                }
                
                // Update last known volume (but only if it's been stable)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.lastVolume = self.audioSession.outputVolume
                }
            }
        }
    }
    
    deinit {
        audioSession?.removeObserver(self, forKeyPath: "outputVolume")
    }
}

// MARK: - Hidden Volume View (required for volume button monitoring)
struct HiddenVolumeView: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let volumeView = MPVolumeView(frame: CGRect(x: -2000, y: -2000, width: 1, height: 1))
        volumeView.showsVolumeSlider = true
        volumeView.alpha = 0.001
        volumeView.clipsToBounds = true
        return volumeView
    }
    
    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}

// MARK: - Shot Data Model
struct Shot: Identifiable {
    let id = UUID()
    let position: CGPoint // Position on screen
    let offsetFromCenter: CGPoint // Offset in feet
    let score: Int // 0-10 (0 = miss)
    let arrowNumber: Int
    let setNumber: Int
    let arrowInSet: Int // Position within the set (1-3 or 1-6)
}

// MARK: - Set Data Model
struct ArrowSet: Identifiable {
    let id = UUID()
    let setNumber: Int
    let shots: [Shot]
    var totalScore: Int {
        shots.map { $0.score }.reduce(0, +)
    }
}

func activeScreenWidth() -> CGFloat? {
    let scenes = UIApplication.shared.connectedScenes
    let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    return (scene as? UIWindowScene)?.screen.bounds.width
}

struct ContentView: View {
    @StateObject private var motionManager = MotionManager()
    @StateObject private var volumeMonitor = VolumeButtonMonitor()
    @State private var cursorPosition = CGPoint(x: activeScreenWidth()! / 2, y: 275)
    @State private var isDragging = false
    
    // Arrow flight simulation parameters (persisted)
    @AppStorage("initialSpeed") private var initialSpeed: Double = Defaults.ArrowSpeed // feet per second
    @AppStorage("distanceToTarget") private var distanceToTarget: Double = Defaults.DistanceToTarget // feet (18m - common indoor distance)
    @AppStorage("targetSize") private var targetSize: Double = Defaults.TargetSize // cm - target face size (40cm, 80cm, or 122cm)
    @State private var launchAngle: Double = 5.0 // degrees (can be set by slider or accelerometer)
    @State private var windage: Double = 0.0 // degrees - horizontal offset from accelerometer roll
    @AppStorage("arrowWeight") private var arrowWeight: Double = Defaults.ArrowWeight // grains
    @AppStorage("arrowDiameter") private var arrowDiameter: Double = Defaults.ArrowDiameter // millimeters
    @AppStorage("drawLength") private var drawLength: Double = Defaults.DrawLength // inches - affects release time
    @AppStorage("dragCoefficient") private var dragCoefficient: Double = Defaults.DragCoefficient // typical for arrows
    
    // Accelerometer control (persisted)
    @State private var accelerometerSensitivity: Double = 2.0 // Multiplier for motion sensitivity
    @AppStorage("audioEffectsEnabled") private var audioEffectsEnabled: Bool = Defaults.AudioEffectsEnabled // Audio effects on/off
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = Defaults.HapticFeedbackEnabled // Haptic feedback on/off
    
    // Simulation results
    @State private var flightResult: ArrowFlightSimulator.FlightResult?
    @State private var currentSetShots: [Shot] = [] // Shots in current set
    @State private var previousSetShots: [Shot] = [] // All previous set shots (for black dots)
    @State private var completedSets: [ArrowSet] = [] // Completed sets
    @State private var currentScore: Int = 0 // Score of current shot
    @State private var currentSetNumber: Int = 1
    @State private var arrowInCurrentSet: Int = 0 // How many arrows shot in current set
    @State private var showSettings = false
    @State private var showResults = false
    @State private var showScoreTable = false
    @State private var showNewCompetitionAlert = false
    @State private var isReleasing = false // True during arrow release
    @State private var isFlyingToTarget = false // True while arrow is in flight
    @State private var tapTriggered = false // True briefly when tap/remote/volume button triggers
    
    // Container dimensions
    let containerHeight: CGFloat = 480.0
    
    // Computed property for target size in feet (based on configurable targetSize in cm)
    var targetHeightFeet: Double {
        targetSize / 30.48 // Convert cm to feet
    }
    
    // Computed properties
    var arrowsPerSet: Int {
        // Convert feet to meters: 1 foot = 0.3048 meters
        let distanceMeters = distanceToTarget * 0.3048
        return distanceMeters < 50 ? 3 : 6
    }
    
    var totalSets: Int { 10 }
    
    var totalScore: Int {
        completedSets.map { $0.totalScore }.reduce(0, +) + currentSetShots.map { $0.score }.reduce(0, +)
    }
    
    var isSetComplete: Bool {
        arrowInCurrentSet >= arrowsPerSet
    }
    
    var isCompetitionComplete: Bool {
        completedSets.count >= totalSets
    }
    
    var currentDistanceText: String {
        let meters = distanceToTarget * 0.3048
        let yards = distanceToTarget / 3
        return String(format: "%.0fm / %.0fyd", meters, yards)
    }
    
    var arrowHoleSize: CGFloat {
        // Calculate arrow hole size proportional to arrow diameter and target size
        // Target visual size is 340 pixels, representing targetSize cm
        let targetVisualSize: CGFloat = 340.0
        
        // Convert arrow diameter from mm to cm
        let arrowDiameterCm = arrowDiameter / 10.0
        
        // Calculate pixels per cm
        let pixelsPerCm = targetVisualSize / targetSize
        
        // Arrow hole size in pixels
        let holeSize = arrowDiameterCm * pixelsPerCm
        
        // Ensure a minimum visible size and maximum for very large arrows
        return max(3, min(20, holeSize))
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.green.opacity(0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 6) {
                Spacer()
                Spacer()
                
                // Header with settings button
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Target Archery")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                        Text(currentDistanceText)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(radius: 3)
                    }
                    
                    Spacer()
                    
                    // Calibrate button
                    Button(action: {
                        motionManager.calibrate()
                    }) {
                        Image(systemName: "scope")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.blue.opacity(0.6))
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    
                    // Settings button
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Archery target with cursor - expanded area for off-target markers
                GeometryReader { geometry in
                    ZStack {
                        // Background for the target area
                        Rectangle()
                            .fill(Color.black.opacity(0.1))
                            .cornerRadius(15)
                        
                        // Target centered in the available space
                        TargetView()
                            .frame(width: 340, height: 340)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        
                        // Aiming cursor - automatically points to predicted hit location or draggable
                        AimingCursor(isDragging: false)
                            .position(cursorPosition)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: cursorPosition)
                        
                        // Previous set markers (arrow holes) - proportional to arrow diameter
                        ForEach(previousSetShots) { shot in
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: arrowHoleSize, height: arrowHoleSize)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.5), lineWidth: max(0.5, arrowHoleSize / 12))
                                )
                                .position(shot.position)
                        }
                        
                        // Current set shot markers (colored with numbers) - fixed size for readability
                        ForEach(currentSetShots) { shot in
                            ZStack {
                                Circle()
                                    .fill(shot.score == 0 ? Color.gray : (shot.score >= 7 ? Color.green : (shot.score >= 4 ? Color.yellow : Color.orange)))
                                    .frame(width: 14, height: 14)
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 14, height: 14)
                                Text("\(shot.arrowInSet)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .position(shot.position)
                            .shadow(radius: 3)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle()) // Make entire area tappable
                    .onTapGesture {
                        // Tap anywhere on target to shoot (works with tap remote or volume buttons)
                        if !isReleasing && !isFlyingToTarget && !isCompetitionComplete {
                            tapTriggered = true
                            simulateFlight()
                            // Clear indicator after 1 second
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                tapTriggered = false
                            }
                        }
                    }
                }
                .frame(height: 480) // Taller frame to show markers outside target
                
                // Motion Info Display
                VStack(spacing: 6) {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.and.down")
                                    .font(.caption2)
                                Text("Elevation")
                                    .font(.caption)
                            }
                            .foregroundColor(.white.opacity(0.7))
                            Text("\(String(format: "%+.1f", motionManager.pitch * accelerometerSensitivity))°")
                                .font(.system(.callout, design: .monospaced))
                                .fontWeight(.semibold)
                                .foregroundColor(motionManager.pitch > 0 ? .green : (motionManager.pitch < 0 ? .orange : .white))
                        }
                        
                        Divider()
                            .frame(height: 30)
                            .background(Color.white.opacity(0.3))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left.and.right")
                                    .font(.caption2)
                                Text("Windage")
                                    .font(.caption)
                            }
                            .foregroundColor(.white.opacity(0.7))
                            Text("\(String(format: "%+.1f", motionManager.roll * accelerometerSensitivity))°")
                                .font(.system(.callout, design: .monospaced))
                                .fontWeight(.semibold)
                                .foregroundColor(abs(motionManager.roll) > 5 ? .yellow : .white)
                        }
                        
                        Divider()
                            .frame(height: 30)
                            .background(Color.white.opacity(0.3))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: tapTriggered ? "hand.tap.fill" : "hand.tap")
                                    .font(.caption2)
                                Text("Remote")
                                    .font(.caption)
                            }
                            .foregroundColor(.white.opacity(0.7))
                            Text(tapTriggered ? "FIRE!" : "Ready")
                                .font(.system(.callout, design: .monospaced))
                                .fontWeight(.semibold)
                                .foregroundColor(tapTriggered ? .green : .white)
                        }
                    }
                    .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.3))
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Scorecard Display (only show during active competition)
                if !isCompetitionComplete {
                    scorecardView
                        .padding(.horizontal)
                        .padding(.top, 4)
                } else {
                    // Competition Complete Summary
                    VStack(spacing: 12) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("🎯 Competition Complete!")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("Final Score: \(totalScore)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        
                        // View Scorecard Button
                        Button(action: {
                            showScoreTable = true
                        }) {
                            HStack {
                                Image(systemName: "list.bullet.rectangle")
                                Text("View Scorecard")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Start New Competition Button
                        Button(action: {
                            showNewCompetitionAlert = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Start New Competition")
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.red]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(radius: 3)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemBackground).opacity(0.9))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 3)
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
            }
            
            // Set Complete Modal (Full Scorecard)
            if showResults && isSetComplete {
                VStack {
                    Spacer()
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            // Header
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(isCompetitionComplete ? "Competition Complete!" : "Set \(currentSetNumber) Complete!")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("Set \(currentSetNumber) of \(totalSets)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        // Complete the final set before closing if needed
                                        if currentSetNumber == totalSets && !currentSetShots.isEmpty {
                                            completeCurrentSet()
                                        }
                                        showResults = false
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            // Tap instruction for remote
                            Text("Tap screen or press remote button to continue")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, -8)
                            
                            // Full Scorecard Table
                            VStack(spacing: 1) {
                                // Table Header
                                HStack(spacing: 0) {
                                    Text("Set")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .frame(width: 35)
                                    
                                    ForEach(1...arrowsPerSet, id: \.self) { i in
                                        Text("\(i)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .frame(maxWidth: .infinity)
                                    }
                                    
                                    Text("Set")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .frame(width: 45)
                                    
                                    Text("Total")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .frame(width: 50)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 8)
                                .background(Color.blue.opacity(0.1))
                                
                                Divider()
                                
                                // All completed sets
                                ForEach(completedSets) { set in
                                    fullScorecardRow(set: set, isCurrent: false)
                                    Divider()
                                }
                                
                                // Current completed set (highlighted)
                                fullScorecardRow(
                                    set: ArrowSet(setNumber: currentSetNumber, shots: currentSetShots),
                                    isCurrent: true
                                )
                                
                                Divider()
                                
                                // Total Row
                                HStack(spacing: 0) {
                                    Text("Grand Total")
                                        .font(.callout)
                                        .fontWeight(.bold)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text("\(totalScore)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple)
                                        .frame(width: 50)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 8)
                                .background(Color.purple.opacity(0.1))
                            }
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            
                            // Action Button
                            if currentSetNumber < totalSets {
                                Button(action: {
                                    withAnimation {
                                        completeCurrentSet()
                                        showResults = false
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.right.circle.fill")
                                        Text("Continue to Set \(currentSetNumber + 1)")
                                    }
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.green, Color.blue]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(radius: 3)
                                }
                            } else {
                                VStack(spacing: 16) {
                                    Text("🏆 All Sets Complete!")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    
                                    Button(action: {
                                        withAnimation {
                                            // Complete the final set before closing
                                            if currentSetNumber == totalSets && !currentSetShots.isEmpty {
                                                completeCurrentSet()
                                            }
                                            showResults = false
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                            Text("Close")
                                        }
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 14)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.green, Color.blue]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(12)
                                        .shadow(radius: 3)
                                    }
                                }
                            }
                            
                            // Extra spacing for safe area
                            Spacer()
                                .frame(height: 8)
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(UIColor.systemBackground))
                            .shadow(color: Color.black.opacity(0.3), radius: 20, y: -5)
                    )
                    .frame(maxHeight: 600)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Allow remote button to advance to next set
                        withAnimation {
                            if currentSetNumber < totalSets {
                                // Continue to next set
                                completeCurrentSet()
                                showResults = false
                            } else {
                                // Close final set
                                if currentSetNumber == totalSets && !currentSetShots.isEmpty {
                                    completeCurrentSet()
                                }
                                showResults = false
                            }
                        }
                    }
                }
                .transition(.move(edge: .bottom))
            }
            
            // Hidden volume view for monitoring volume button presses
            HiddenVolumeView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                initialSpeed: $initialSpeed,
                distanceToTarget: $distanceToTarget,
                targetSize: $targetSize,
                arrowWeight: $arrowWeight,
                arrowDiameter: $arrowDiameter,
                drawLength: $drawLength,
                dragCoefficient: $dragCoefficient,
                audioEffectsEnabled: $audioEffectsEnabled,
                hapticFeedbackEnabled: $hapticFeedbackEnabled,
                motionManager: motionManager
            )
        }
        .sheet(isPresented: $showScoreTable) {
            ScoreTableView(
                completedSets: completedSets,
                currentSetShots: currentSetShots,
                currentSetNumber: currentSetNumber,
                onClear: {
                    withAnimation {
                        resetCompetition()
                    }
                }
            )
        }
        .alert("Start New Competition?", isPresented: $showNewCompetitionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Start New", role: .destructive) {
                withAnimation {
                    resetCompetition()
                    showResults = false
                }
            }
        } message: {
            Text("This will clear all scores from the current competition. Your final score was \(totalScore) points.")
        }
        .onChange(of: initialSpeed) { _ in updateCursorPosition() }
        .onChange(of: distanceToTarget) { _ in
            updateCursorPosition()
            // Reset competition when distance changes (different distance = different competition)
            if !currentSetShots.isEmpty || !completedSets.isEmpty {
                resetCompetition()
            }
        }
        .onChange(of: targetSize) { _ in
            // Reset competition when target size changes (different target = different competition)
            if !currentSetShots.isEmpty || !completedSets.isEmpty {
                resetCompetition()
            }
        }
        .onChange(of: arrowWeight) { _ in updateCursorPosition() }
        .onChange(of: arrowDiameter) { _ in updateCursorPosition() }
        .onChange(of: dragCoefficient) { _ in updateCursorPosition() }
        .onChange(of: motionManager.pitch) { newPitch in
            // With vertical phone holding:
            // - Moving arm UP (device tilts back) = positive pitch = aim higher
            // - Moving arm DOWN (device tilts forward) = negative pitch = aim lower
            let baseAngle = 5.0 // Base angle when device is at calibrated position
            let pitchAngle = newPitch * accelerometerSensitivity
            launchAngle = max(-10, min(45, baseAngle + pitchAngle))
            updateCursorPosition()
        }
        .onChange(of: motionManager.roll) { newRoll in
            // With vertical phone holding:
            // - Moving arm LEFT (device tilts left) = negative roll = aim left
            // - Moving arm RIGHT (device tilts right) = positive roll = aim right
            windage = newRoll * accelerometerSensitivity
            updateCursorPosition()
        }
        .onChange(of: volumeMonitor.volumePressed) { pressed in
            // Volume button (selfie remote) triggers arrow shot or advances to next set
            if pressed {
                // If set complete modal is showing, advance to next set
                if showResults && isSetComplete {
                    withAnimation {
                        if currentSetNumber < totalSets {
                            // Continue to next set
                            completeCurrentSet()
                            showResults = false
                        } else {
                            // Close final set
                            if currentSetNumber == totalSets && !currentSetShots.isEmpty {
                                completeCurrentSet()
                            }
                            showResults = false
                        }
                    }
                }
                // Otherwise, shoot arrow if conditions allow
                else if !isReleasing && !isFlyingToTarget && !isCompetitionComplete {
                    tapTriggered = true
                    simulateFlight()
                    // Clear indicator after 1 second
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        tapTriggered = false
                    }
                }
            }
        }
        .onChange(of: audioEffectsEnabled) { enabled in
            // Update SoundManager when audio setting changes
            SoundManager.shared.audioEffectsEnabled = enabled
        }
        .onChange(of: hapticFeedbackEnabled) { enabled in
            // Update SoundManager when haptic setting changes
            SoundManager.shared.hapticFeedbackEnabled = enabled
        }
        .onAppear {
            updateCursorPosition()
            // Initialize SoundManager settings
            SoundManager.shared.audioEffectsEnabled = audioEffectsEnabled
            SoundManager.shared.hapticFeedbackEnabled = hapticFeedbackEnabled
        }
    }
    
    // MARK: - Scorecard View (Current Set Only)
    
    private var scorecardView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Set \(currentSetNumber) of \(totalSets)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Current Set")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(totalScore)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            
            // Current Set Scorecard
            VStack(spacing: 1) {
                // Table Header
                HStack(spacing: 0) {
                    Text("Arrow")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .frame(width: 50, alignment: .leading)
                    
                    // Arrow columns
                    ForEach(1...arrowsPerSet, id: \.self) { i in
                        Text("\(i)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Text("Total")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .frame(width: 50, alignment: .trailing)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.gray.opacity(0.2))
                
                Divider()
                
                // Current set scores
                HStack(spacing: 0) {
                    Text("Score")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 50, alignment: .leading)
                    
                    ForEach(1...arrowsPerSet, id: \.self) { i in
                        if i <= currentSetShots.count {
                            Text("\(currentSetShots[i-1].score)")
                                .font(.callout)
                                .fontWeight(.bold)
                                .foregroundColor(scoreColor(currentSetShots[i-1].score))
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("-")
                                .font(.callout)
                                .foregroundColor(.gray.opacity(0.3))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // Set total so far
                    let currentSetTotal = currentSetShots.map { $0.score }.reduce(0, +)
                    Text("\(currentSetTotal)")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .frame(width: 50, alignment: .trailing)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.orange.opacity(0.05))
            }
            .background(Color(UIColor.systemBackground))
        }
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 3)
    }
    
    private func scoreColor(_ score: Int) -> Color {
        if score >= 9 { return .green }
        else if score >= 7 { return .blue }
        else if score >= 5 { return .orange }
        else if score > 0 { return .red }
        else { return .gray }
    }
    
    private func fullScorecardRow(set: ArrowSet, isCurrent: Bool) -> some View {
        // Calculate running total
        let runningTotal: Int = {
            if isCurrent {
                return totalScore
            } else {
                let index = completedSets.firstIndex(where: { $0.id == set.id }) ?? 0
                return completedSets.prefix(through: index).map { $0.totalScore }.reduce(0, +)
            }
        }()
        
        return HStack(spacing: 0) {
            Text("\(set.setNumber)")
                .font(.callout)
                .fontWeight(isCurrent ? .bold : .regular)
                .foregroundColor(isCurrent ? .orange : .primary)
                .frame(width: 35)
            
            // Arrow scores
            ForEach(0..<arrowsPerSet, id: \.self) { i in
                if i < set.shots.count {
                    Text("\(set.shots[i].score)")
                        .font(isCurrent ? .callout : .subheadline)
                        .fontWeight(isCurrent ? .bold : .semibold)
                        .foregroundColor(scoreColor(set.shots[i].score))
                        .frame(maxWidth: .infinity)
                } else {
                    Text("-")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Set total
            Text("\(set.totalScore)")
                .font(.callout)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .frame(width: 45)
            
            // Running total
            Text("\(runningTotal)")
                .font(.callout)
                .fontWeight(.bold)
                .foregroundColor(.purple)
                .frame(width: 50)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(isCurrent ? Color.green.opacity(0.1) : Color.clear)
    }
    
    // MARK: - Helper Functions
    
    private func resultRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
    
    /// Calculate score (0-10) based on distance from center
    /// Target is 4 feet tall = 340 pixels
    /// Each zone is 10% of radius (0.2 feet = 17 pixels)
    private func calculateScore(offsetFromCenter: CGPoint) -> Int {
        // Convert target size from cm to feet
        let targetRadiusCm = targetSize / 2.0
        let targetRadius = targetRadiusCm / 30.48 // Convert cm to feet
        
        // Distance from arrow center to target center
        let distance = sqrt(offsetFromCenter.x * offsetFromCenter.x + offsetFromCenter.y * offsetFromCenter.y)
        
        // Convert arrow diameter from mm to feet
        let arrowRadiusFeet = (arrowDiameter / 2.0) / 304.8
        
        // Subtract arrow radius to get the closest edge (benefit of the doubt)
        // If any part of the arrow touches a higher zone, count the higher score
        let effectiveDistance = max(0, distance - arrowRadiusFeet)
        
        // 10 zones, each 10% of radius
        let zoneSize = targetRadius / 10.0
        
        if distance - arrowRadiusFeet > targetRadius {
            return 0 // Miss (even the edge doesn't touch the target)
        }
        
        // Calculate which zone (1-10, where 1 is outer, 10 is center)
        let zone = Int(effectiveDistance / zoneSize)
        return max(1, 10 - zone) // Invert so center = 10
    }
    
    private func updateCursorPosition() {
        // Run simulation to get predicted hit location
        let simulator = ArrowFlightSimulator(
            initialSpeed: initialSpeed,
            distanceToTarget: distanceToTarget,
            launchAngle: launchAngle,
            arrowWeight: arrowWeight,
            arrowDiameter: arrowDiameter,
            dragCoefficient: dragCoefficient
        )
        
        let result = simulator.simulate()
        
        if result.hitTarget {
            let hitPosition = simulator.hitPositionOnTarget(result: result)
            
            // Convert feet offset to screen coordinates
            let pixelsPerFoot = 340.0 / targetHeightFeet
            let centerY = containerHeight / 2.0 // 275
            let centerX = UIScreen.main.bounds.width / 2.0
            
            // Vertical offset (negative because SwiftUI y increases downward)
            let yOffset = -hitPosition.y * pixelsPerFoot
            let calculatedY = centerY + yOffset
            
            // Horizontal offset from windage (convert degrees to pixels)
            // Map windage degrees to horizontal screen space
            // At 20 feet, 1 degree ≈ 0.35 feet horizontal offset
            // Use similar pixel conversion as vertical
            let windageOffset = windage * 10.0 // Scale windage to reasonable screen movement
            let calculatedX = centerX + windageOffset
            
            // Define target bounds
            //let targetRadius: CGFloat = 170.0 // 340/2
            //let targetTop = centerY - targetRadius
            //let targetBottom = centerY + targetRadius
            let screenTop: CGFloat = 10.0
            let screenBottom: CGFloat = containerHeight - 10.0
            
            // Define horizontal bounds (allow some off-screen movement)
            let screenLeft: CGFloat = 20.0
            let screenRight: CGFloat = UIScreen.main.bounds.width - 20.0
            
            // Clamp to screen bounds
            let finalY = max(screenTop, min(screenBottom, calculatedY))
            let finalX = max(screenLeft, min(screenRight, calculatedX))
            
            cursorPosition = CGPoint(x: finalX, y: finalY)
        } else {
            // If arrow doesn't hit target, position cursor at bottom
            let centerX = UIScreen.main.bounds.width / 2.0
            let windageOffset = windage * 10.0
            let finalX = max(20.0, min(UIScreen.main.bounds.width - 20.0, centerX + windageOffset))
            cursorPosition = CGPoint(x: finalX, y: containerHeight - 20)
        }
    }
    
    private func simulateFlight() {
        // Don't allow shooting if competition is complete
        guard !isCompetitionComplete else { return }
        
        // Calculate arrow release time based on draw length
        // Arrow travels at initialSpeed, so time = length / speed
        let drawLengthFeet = drawLength / 12.0 // Convert inches to feet
        let releaseTime = drawLengthFeet / initialSpeed // Time for arrow to leave bow
        
        // Mark that we're in release phase
        isReleasing = true
        
        // Play release sound
        SoundManager.shared.playSound("release")
        SoundManager.shared.playHaptic(.light)
        
        // After release time, capture final aim and run simulation
        DispatchQueue.main.asyncAfter(deadline: .now() + releaseTime) {
            self.isReleasing = false
            self.isFlyingToTarget = true
            
            // Accelerometer mode: Run full physics simulation
            let simulator = ArrowFlightSimulator(
                initialSpeed: self.initialSpeed,
                distanceToTarget: self.distanceToTarget,
                launchAngle: self.launchAngle,
                arrowWeight: self.arrowWeight,
                arrowDiameter: self.arrowDiameter,
                dragCoefficient: self.dragCoefficient
            )
            
            let result = simulator.simulate()
            let flightDelay = result.hitTarget ? result.timeToTarget : 0.5
            self.flightResult = result
            
            // Wait for flight time, then show hit
            DispatchQueue.main.asyncAfter(deadline: .now() + flightDelay) {
                self.isFlyingToTarget = false
                self.showHitResult(result: result)
            }
        }
    }
    
    private func checkSetCompletion() {
        // Auto-dismiss will be cancelled - we'll show set summary instead
    }
    
    private func completeCurrentSet() {
        // Save the current set
        let completedSet = ArrowSet(setNumber: currentSetNumber, shots: currentSetShots)
        completedSets.append(completedSet)
        
        // Move current shots to previous shots (as black dots)
        previousSetShots.append(contentsOf: currentSetShots)
        
        // Clear current set
        currentSetShots.removeAll()
        arrowInCurrentSet = 0
        currentSetNumber += 1
        
        // Check if competition is complete
        if isCompetitionComplete {
            // Show score table automatically
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showScoreTable = true
            }
        }
    }
    
    private func resetCompetition() {
        completedSets.removeAll()
        currentSetShots.removeAll()
        previousSetShots.removeAll()
        currentSetNumber = 1
        arrowInCurrentSet = 0
        currentScore = 0
        showResults = false
        showScoreTable = false
    }
    
    private func showHitResult(result: ArrowFlightSimulator.FlightResult) {
        // Don't process results if competition is already complete
        guard !isCompetitionComplete else { return }
        
        // In manual mode, use cursor position directly instead of simulation
        let hitPosition: (x: Double, y: Double)
        let finalPosition: CGPoint
        
        // Accelerometer mode: Use physics simulation
        if !result.hitTarget {
            // Handle miss
            currentScore = 0
            arrowInCurrentSet += 1
            
            // Play miss sound
            SoundManager.shared.playSound("miss")
            SoundManager.shared.playHaptic(.light)
            
            let missShot = Shot(
                position: CGPoint(x: UIScreen.main.bounds.width / 2, y: containerHeight - 20),
                offsetFromCenter: CGPoint(x: 999, y: 999),
                score: 0,
                arrowNumber: (completedSets.count * arrowsPerSet) + arrowInCurrentSet,
                setNumber: currentSetNumber,
                arrowInSet: arrowInCurrentSet
            )
            
            withAnimation(.spring()) {
                currentSetShots.append(missShot)
            }
            
            if isSetComplete {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        showResults = true
                        checkSetCompletion()
                    }
                }
            }
            return
        }
        
        let simulatorHitPosition = ArrowFlightSimulator(
            initialSpeed: initialSpeed,
            distanceToTarget: distanceToTarget,
            launchAngle: launchAngle,
            arrowWeight: arrowWeight,
            arrowDiameter: arrowDiameter,
            dragCoefficient: dragCoefficient
        ).hitPositionOnTarget(result: result)
        
        let pixelsPerFoot = 340.0 / self.targetHeightFeet
        let centerY = self.containerHeight / 2.0
        let centerX = UIScreen.main.bounds.width / 2.0
        
        let yOffset = -simulatorHitPosition.y * pixelsPerFoot
        let calculatedY = centerY + yOffset
        
        let windageOffset = windage * 10.0
        let calculatedX = centerX + windageOffset
        
        let screenTop: CGFloat = 10.0
        let screenBottom: CGFloat = self.containerHeight - 10.0
        let screenLeft: CGFloat = 20.0
        let screenRight: CGFloat = UIScreen.main.bounds.width - 20.0
        
        let finalY = max(screenTop, min(screenBottom, calculatedY))
        let finalX = max(screenLeft, min(screenRight, calculatedX))
        finalPosition = CGPoint(x: finalX, y: finalY)
        
        // Convert windage pixel offset to feet for scoring
        let windageOffsetFeet = windageOffset / pixelsPerFoot
        hitPosition = (x: windageOffsetFeet, y: simulatorHitPosition.y)
        
        // Calculate score (common for both modes)
        let score = calculateScore(offsetFromCenter: CGPoint(x: hitPosition.x, y: hitPosition.y))
        currentScore = score
        
        // Play appropriate sound
        if score > 0 {
            SoundManager.shared.playSound("hit")
            SoundManager.shared.playHaptic(score >= 7 ? .heavy : .medium)
        } else {
            SoundManager.shared.playSound("miss")
            SoundManager.shared.playHaptic(.light)
        }
        
        arrowInCurrentSet += 1
        
        let shot = Shot(
            position: finalPosition,
            offsetFromCenter: CGPoint(x: hitPosition.x, y: hitPosition.y),
            score: score,
            arrowNumber: (completedSets.count * arrowsPerSet) + arrowInCurrentSet,
            setNumber: currentSetNumber,
            arrowInSet: arrowInCurrentSet
        )
        
        withAnimation(.spring()) {
            currentSetShots.append(shot)
        }
        
        // Only show results if set is complete
        if isSetComplete {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    showResults = true
                    checkSetCompletion()
                }
            }
        }
    }
}

// MARK: - Score Table View
struct ScoreTableView: View {
    let completedSets: [ArrowSet]
    let currentSetShots: [Shot]
    let currentSetNumber: Int
    let onClear: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var allSets: [ArrowSet] {
        var sets = completedSets
        // Add current set if it has shots
        if !currentSetShots.isEmpty {
            sets.append(ArrowSet(setNumber: currentSetNumber, shots: currentSetShots))
        }
        return sets
    }
    
    var totalScore: Int {
        allSets.map { $0.totalScore }.reduce(0, +)
    }
    
    var totalArrows: Int {
        allSets.map { $0.shots.count }.reduce(0, +)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if allSets.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "target")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No sets yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Start shooting to track your scores!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // Sets Section
                        Section(header: Text("Sets")) {
                            ForEach(allSets) { set in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Set \(set.setNumber)")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        
                                        if set.setNumber == currentSetNumber && !currentSetShots.isEmpty {
                                            Text("(In Progress)")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.1))
                                                .cornerRadius(4)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("\(set.totalScore)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                        Text("pts")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    // Individual arrow scores
                                    HStack(spacing: 8) {
                                        ForEach(set.shots) { shot in
                                            VStack(spacing: 2) {
                                                Text("\(shot.score)")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(shot.score >= 7 ? .green : (shot.score >= 4 ? .orange : (shot.score > 0 ? .red : .gray)))
                                                Circle()
                                                    .fill(shot.score >= 7 ? Color.green : (shot.score >= 4 ? Color.orange : (shot.score > 0 ? Color.red : Color.gray)))
                                                    .frame(width: 6, height: 6)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        // Running Total Section
                        Section(header: Text("Running Totals")) {
                            ForEach(Array(allSets.enumerated()), id: \.element.id) { index, set in
                                let runningTotal = allSets.prefix(index + 1).map { $0.totalScore }.reduce(0, +)
                                HStack {
                                    Text("After Set \(set.setNumber)")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(runningTotal)")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple)
                                    Text("pts")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        // Summary Section
                        Section(header: Text("Summary")) {
                            HStack {
                                Text("Sets Completed")
                                Spacer()
                                Text("\(completedSets.count) of 10")
                                    .fontWeight(.semibold)
                            }
                            HStack {
                                Text("Total Arrows")
                                Spacer()
                                Text("\(totalArrows)")
                                    .fontWeight(.semibold)
                            }
                            HStack {
                                Text("Total Score")
                                Spacer()
                                Text("\(totalScore)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            HStack {
                                Text("Average per Arrow")
                                Spacer()
                                Text(String(format: "%.2f", Double(totalScore) / Double(max(1, totalArrows))))
                                    .fontWeight(.semibold)
                            }
                            HStack {
                                Text("Average per Set")
                                Spacer()
                                Text(String(format: "%.1f", Double(totalScore) / Double(max(1, allSets.count))))
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Score Table")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if !allSets.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            onClear()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear")
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
