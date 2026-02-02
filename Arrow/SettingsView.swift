//
//  SettingsView.swift
//  Arrow
//
//  Created on 1/9/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var initialSpeed: Double
    @Binding var distanceToTarget: Double
    @Binding var targetSize: Double
    @Binding var targetStyle: String
    @Binding var arrowWeight: Double
    @Binding var arrowDiameter: Double
    @Binding var drawLength: Double
    @Binding var dragCoefficient: Double
    @Binding var audioEffectsEnabled: Bool
    @Binding var hapticFeedbackEnabled: Bool
    
    @ObservedObject var motionManager: MotionManager
    
    @State private var showAdvancedPhysics = false
    
    // Helper function to check if current distance matches a preset (within tolerance)
    private func isDistanceActive(_ meters: Double) -> Bool {
        let targetFeet = meters / 0.3048
        return abs(distanceToTarget - targetFeet) < 1.0 // 1 foot tolerance
    }
    
    private func isYardsActive(_ yards: Double) -> Bool {
        let targetFeet = yards * 3.0
        return abs(distanceToTarget - targetFeet) < 1.0 // 1 foot tolerance
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Audio & Haptics")) {
                    Toggle(isOn: $audioEffectsEnabled) {
                        HStack(spacing: 8) {
                            Image(systemName: audioEffectsEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                                .foregroundColor(audioEffectsEnabled ? .blue : .gray)
                            Text("Sound Effects")
                        }
                    }
                    
                    Text("Play sounds when shooting arrows (hit, miss, release)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Toggle(isOn: $hapticFeedbackEnabled) {
                        HStack(spacing: 8) {
                            Image(systemName: hapticFeedbackEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash")
                                .foregroundColor(hapticFeedbackEnabled ? .blue : .gray)
                            Text("Haptic Feedback")
                        }
                    }
                    
                    Text("Vibration feedback when shooting arrows")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Motion Control")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Angle Sensitivity")
                            Spacer()
                            Text(String(format: "%.1fx", motionManager.angleSensitivity))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $motionManager.angleSensitivity, in: 0.5...5.0, step: 0.25)
                        Text("How much tilting the phone affects cursor position (higher = more sensitive)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Dampening (Smoothing)")
                            Spacer()
                            Text(String(format: "%.0f%%", motionManager.dampening * 100))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $motionManager.dampening, in: 0.05...0.50, step: 0.05)
                        Text("Movement smoothness (lower = smoother/slower, higher = more responsive/jittery)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Range Setup")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Target Style")
                            Spacer()
                            Text(TargetStyle(rawValue: targetStyle)?.detailLabel ?? TargetStyle.targetArchery.detailLabel)
                                .foregroundColor(.secondary)
                        }
                        Picker("Target Style", selection: $targetStyle) {
                            ForEach(TargetStyle.allCases) { style in
                                Text(style.title).tag(style.rawValue)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        Text("Target archery uses 10 rings; field archery uses 6 rings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Initial Speed")
                            Spacer()
                            Text("\(Int(initialSpeed)) ft/s")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $initialSpeed, in: 50...300, step: 5)
                        Text("Arrow speed from the bow")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Distance to Target")
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(String(format: "%.0f", distanceToTarget / 3)) yd")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Text("(\(String(format: "%.1f", distanceToTarget * 0.3048)) m)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Slider(value: $distanceToTarget, in: 10...300, step: 5)
                        Text("Standard distances: 18m, 25m, 30m, 50m, 70m, 90m")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("< 50m = 3 arrows/set  •  ≥ 50m = 6 arrows/set")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Target Face Size")
                            Spacer()
                            Text("\(Int(targetSize)) cm")
                                .foregroundColor(.secondary)
                        }
                        Picker("Target Size", selection: $targetSize) {
                            Text("40 cm").tag(40.0)
                            Text("80 cm").tag(80.0)
                            Text("122 cm").tag(122.0)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        Text("Standard: 40cm (<50m), 80cm (50m), 122cm (≥60m)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Arrow Equipment")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Arrow Weight")
                            Spacer()
                            Text("\(Int(arrowWeight)) grains")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $arrowWeight, in: 250...600, step: 10)
                        Text("Heavier arrows drop more but are less affected by drag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Draw Length")
                            Spacer()
                            Text(String(format: "%.1f", drawLength) + " in")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $drawLength, in: 24...32, step: 0.5)
                        Text("Affects release time - longer arrows take more time to leave bow")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Advanced Physics")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Arrow Diameter")
                            Spacer()
                            Text(String(format: "%.1f", arrowDiameter) + " mm")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $arrowDiameter, in: 3.0...11.0, step: 0.1)
                        Text("Affects cross-sectional area and air resistance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Drag Coefficient")
                            Spacer()
                            Text(String(format: "%.2f", dragCoefficient))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $dragCoefficient, in: 0.3...0.8, step: 0.05)
                        Text("Arrow aerodynamics (lower = more streamlined)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Distance Presets")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meters (Tournament)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Button("18m") {
                                distanceToTarget = 18 / 0.3048 // Convert meters to feet
                                targetSize = 40.0 // 40cm target for < 50m
                                targetStyle = TargetStyle.targetArchery.rawValue
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .tint(isDistanceActive(18) ? .blue : .gray)
                            
                            Button("25m") {
                                distanceToTarget = 25 / 0.3048
                                targetSize = 40.0 // 40cm target for < 50m
                                targetStyle = TargetStyle.targetArchery.rawValue
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .tint(isDistanceActive(25) ? .blue : .gray)
                            
                            Button("30m") {
                                distanceToTarget = 30 / 0.3048
                                targetSize = 40.0 // 40cm target for < 50m
                                targetStyle = TargetStyle.targetArchery.rawValue
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .tint(isDistanceActive(30) ? .blue : .gray)
                            
                            Button("50m") {
                                distanceToTarget = 50 / 0.3048
                                targetSize = 80.0 // 80cm target for 50m
                                targetStyle = TargetStyle.targetArchery.rawValue
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .tint(isDistanceActive(50) ? .blue : .gray)
                        }
                        
                        HStack {
                            Button("60m") {
                                distanceToTarget = 60 / 0.3048
                                targetSize = 122.0 // 122cm target for ≥ 60m
                                targetStyle = TargetStyle.targetArchery.rawValue
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .tint(isDistanceActive(60) ? .blue : .gray)
                            
                            Button("70m") {
                                distanceToTarget = 70 / 0.3048
                                targetSize = 122.0 // 122cm target for ≥ 60m
                                targetStyle = TargetStyle.targetArchery.rawValue
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .tint(isDistanceActive(70) ? .blue : .gray)
                            
                            Button("90m") {
                                distanceToTarget = 90 / 0.3048
                                targetSize = 122.0 // 122cm target for ≥ 60m
                                targetStyle = TargetStyle.targetArchery.rawValue
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .tint(isDistanceActive(90) ? .blue : .gray)
                            
                            Spacer()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Yards (Field Archery)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Button("20yd") {
                                distanceToTarget = 20 * 3 // Convert yards to feet
                                targetSize = 40.0 // 20 yd = 18.3m, use 40cm
                                targetStyle = TargetStyle.fieldArchery.rawValue
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .tint(isYardsActive(20) ? .blue : .gray)
                            
                            Button("30yd") {
                                distanceToTarget = 30 * 3
                                targetSize = 40.0 // 30 yd = 27.4m, use 40cm
                                targetStyle = TargetStyle.fieldArchery.rawValue
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .tint(isYardsActive(30) ? .blue : .gray)
                            
                            Button("40yd") {
                                distanceToTarget = 40 * 3
                                targetSize = 40.0 // 40 yd = 36.6m, use 40cm
                                targetStyle = TargetStyle.fieldArchery.rawValue
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .tint(isYardsActive(40) ? .blue : .gray)
                            
                            Button("50yd") {
                                distanceToTarget = 50 * 3
                                targetSize = 80.0 // 50 yd = 45.7m, use 80cm
                                targetStyle = TargetStyle.fieldArchery.rawValue
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .tint(isYardsActive(50) ? .blue : .gray)
                            
                            Button("60yd") {
                                distanceToTarget = 60 * 3
                                targetSize = 122.0 // 60 yd = 54.9m, use 122cm
                                targetStyle = TargetStyle.fieldArchery.rawValue
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .tint(isYardsActive(60) ? .blue : .gray)
                        }
                    }
                }
                
                Section(header: Text("Arrow Presets")) {
                    Button("Ultra Light Arrow (350gr, 28in, 4.2mm)") {
                        arrowWeight = 350
                        drawLength = 28
                        arrowDiameter = 4.2
                        dragCoefficient = 0.50
                    }
                    
                    Button("Standard Arrow (400gr, 28in, 7mm)") {
                        arrowWeight = Defaults.ArrowWeight
                        drawLength = Defaults.DrawLength
                        arrowDiameter = Defaults.ArrowDiameter
                        dragCoefficient = Defaults.DragCoefficient
                    }
                    
                    Button("Heavy Indoor Arrow (500gr, 30in, 9mm)") {
                        arrowWeight = 500
                        drawLength = 30
                        arrowDiameter = 9.0
                        dragCoefficient = 0.60
                    }
                }
                
                Section(header: Text("About Physics Simulation")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This simulation uses:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("• Gravity: 32.174 ft/s²")
                        Text("• Air density: 0.0765 lb/ft³")
                        Text("• Numerical integration (Euler method)")
                        Text("• Quadratic drag forces")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(
            initialSpeed: .constant(Defaults.ArrowSpeed),
            distanceToTarget: .constant(59), // 18m
            targetSize: .constant(40.0), // 40cm
            targetStyle: .constant(TargetStyle.targetArchery.rawValue),
            arrowWeight: .constant(Defaults.ArrowWeight),
            arrowDiameter: .constant(Defaults.ArrowDiameter),
            drawLength: .constant(Defaults.DrawLength),
            dragCoefficient: .constant(0.55),
            audioEffectsEnabled: .constant(true),
            hapticFeedbackEnabled: .constant(true),
            motionManager: MotionManager()
        )
    }
}
