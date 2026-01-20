//
//  ArrowFlightSimulator.swift
//  Arrow
//
//  Created on 1/8/26.
//

import Foundation
import CoreGraphics

struct ArrowFlightSimulator {
    // Physics constants
    static let gravity: Double = 32.174 // ft/s² (feet per second squared)
    static let archerHeight: Double = 5.0 // feet - height where arrow starts
    static let targetCenterHeight: Double = 5.0 // feet - height of target center
    static let airDensity: Double = 0.0765 // lb/ft³ at sea level
    
    // Simulation parameters
    var initialSpeed: Double // feet per second
    var distanceToTarget: Double // feet
    var launchAngle: Double // degrees
    var arrowWeight: Double // grains (1 grain = 1/7000 lb)
    var arrowDiameter: Double // millimeters
    var dragCoefficient: Double // dimensionless (~0.5-0.6 for arrows)
    
    // Results
    struct FlightResult {
        let hitHeight: Double // feet - height at target distance
        let timeToTarget: Double // seconds
        let maxHeight: Double // feet
        let hitTarget: Bool // whether arrow reaches target
        let impactVerticalVelocity: Double // ft/s
        let impactAngle: Double // degrees
    }
    
    /// Calculate where the arrow hits given the launch parameters
    /// Uses numerical integration to account for air resistance
    func simulate() -> FlightResult {
        // Convert arrow weight from grains to pounds (1 grain = 1/7000 lb)
        let mass = arrowWeight / 7000.0 // lb
        
        // Calculate cross-sectional area from diameter
        let diameterFeet = arrowDiameter / 304.8 // convert mm to feet
        let crossSectionalArea = .pi * (diameterFeet / 2.0) * (diameterFeet / 2.0) // ft²
        
        // Drag constant: k = 0.5 * ρ * C_d * A
        let k = 0.5 * Self.airDensity * dragCoefficient * crossSectionalArea
        
        // Convert angle to radians
        let angleRad = launchAngle * .pi / 180.0
        
        // Initial conditions
        var vx = initialSpeed * cos(angleRad)
        var vy = initialSpeed * sin(angleRad)
        var x: Double = 0.0
        var y: Double = Self.archerHeight
        var t: Double = 0.0
        
        let dt: Double = 0.001 // time step (1 millisecond)
        var maxHeight = Self.archerHeight
        var hitHeight: Double = 0.0
        var timeToTarget: Double = 0.0
        var vyAtImpact: Double = 0.0
        var vxAtImpact: Double = 0.0
        var hitTarget = false
        
        // Numerical integration using Euler method
        while t < 10.0 { // max 10 seconds simulation
            // Check if we've reached the target distance
            if x >= distanceToTarget && !hitTarget {
                hitHeight = y
                timeToTarget = t
                vyAtImpact = vy
                vxAtImpact = vx
                hitTarget = y >= 0 // Arrow must be above ground
                break
            }
            
            // Check if arrow hit the ground
            if y < 0 {
                break
            }
            
            // Calculate velocity magnitude for drag
            let v = sqrt(vx * vx + vy * vy)
            
            // Drag force components: F_drag = -k * v² * (v_component / v)
            // This gives drag opposite to velocity direction
            let dragX = -k * v * vx // simplified: k * v * vx is drag in x direction
            let dragY = -k * v * vy
            
            // Acceleration components
            let ax = dragX / mass
            let ay = -Self.gravity + (dragY / mass)
            
            // Update velocities
            vx += ax * dt
            vy += ay * dt
            
            // Update positions
            x += vx * dt
            y += vy * dt
            
            // Update time
            t += dt
            
            // Track maximum height
            if y > maxHeight {
                maxHeight = y
            }
        }
        
        // Calculate impact angle
        let impactAngle = atan2(-vyAtImpact, vxAtImpact) * 180.0 / .pi
        
        return FlightResult(
            hitHeight: hitHeight,
            timeToTarget: timeToTarget,
            maxHeight: maxHeight,
            hitTarget: hitTarget,
            impactVerticalVelocity: vyAtImpact,
            impactAngle: impactAngle
        )
    }
    
    /// Convert hit height to target coordinates
    /// Returns the vertical offset from center in the target coordinate system
    func hitPositionOnTarget(result: FlightResult) -> (x: Double, y: Double) {
        // Target center is at 5 feet height
        // Calculate offset from center
        let verticalOffset = result.hitHeight - Self.targetCenterHeight
        
        // Return position (x=0 for center hit, y is vertical offset)
        return (x: 0.0, y: verticalOffset)
    }
    
    /// Calculate trajectory points for visualization
    func calculateTrajectory(numPoints: Int = 50) -> [(distance: Double, height: Double)] {
        // Convert arrow weight from grains to pounds
        let mass = arrowWeight / 7000.0
        
        // Calculate cross-sectional area
        let diameterFeet = arrowDiameter / 304.8 // convert mm to feet
        let crossSectionalArea = .pi * (diameterFeet / 2.0) * (diameterFeet / 2.0)
        
        // Drag constant
        let k = 0.5 * Self.airDensity * dragCoefficient * crossSectionalArea
        
        // Convert angle to radians
        let angleRad = launchAngle * .pi / 180.0
        
        // Initial conditions
        var vx = initialSpeed * cos(angleRad)
        var vy = initialSpeed * sin(angleRad)
        var x: Double = 0.0
        var y: Double = Self.archerHeight
        
        var points: [(Double, Double)] = [(x, y)]
        
        let dt: Double = 0.01 // time step
        let targetDistance = distanceToTarget * 1.2 // go a bit beyond target
        
        // Numerical integration
        while x < targetDistance && y >= 0 && points.count < 1000 {
            // Calculate velocity magnitude for drag
            let v = sqrt(vx * vx + vy * vy)
            
            // Drag force components
            let dragX = -k * v * vx
            let dragY = -k * v * vy
            
            // Acceleration components
            let ax = dragX / mass
            let ay = -Self.gravity + (dragY / mass)
            
            // Update velocities
            vx += ax * dt
            vy += ay * dt
            
            // Update positions
            x += vx * dt
            y += vy * dt
            
            // Add point periodically
            if points.count < numPoints {
                let interval = max(1, 1000 / numPoints)
                if points.count % interval == 0 {
                    points.append((x, y))
                }
            }
        }
        
        return points
    }
}
