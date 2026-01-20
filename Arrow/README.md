# Target Archery iOS Game

A SwiftUI-based iOS application featuring an interactive archery target game.

## Features

- **Realistic Archery Target**: Multi-colored target rings following standard archery target design
  - White outer ring
  - Black ring
  - Blue ring
  - Red ring
  - Yellow ring
  - Yellow center bullseye with red dot

- **Interactive Aiming Cursor**: 
  - Draggable crosshair for precise aiming
  - Pulsing animation effect
  - Scale effect when dragging
  - Red crosshair with white outline for visibility

- **Arrow Flight Simulation**: 
  - Physics-based projectile motion simulation with air resistance
  - Adjustable parameters:
    - Initial speed (50-300 ft/s, default 140 ft/s)
    - Distance to target (10-100 feet)
    - Launch angle (-10° to 45°)
    - Arrow weight (250-600 grains, default 400)
    - Arrow diameter (0.20-0.35 inches, default 0.28)
    - Drag coefficient (0.3-0.8, default 0.55)
  - Real-time calculation of arrow trajectory accounting for:
    - Arrow mass and cross-sectional area
    - Air resistance (drag forces)
    - Gravitational drop
  - Visual hit marker showing where arrow would land:
    - Green marker: Arrow hits within the target
    - Yellow marker: Arrow hits outside target (displayed at actual position above/below target to show how far off the shot was)
  - Detailed flight results including:
    - Hit height at target distance
    - Time to reach target
    - Maximum height during flight
    - Impact angle
    - Impact velocity
    - Warning when hit is outside visible target area

- **User Interface**:
  - Beautiful gradient background
  - Clean, focused main screen with minimal controls
  - Settings accessible via gear icon
  - No scrolling required on main screen
  - Smooth animations using SwiftUI
  - Compact bottom panel for flight results (doesn't obscure target)
  - Intuitive touch gestures (tap to dismiss, drag to aim)

## Project Structure

```
arrow/
├── ArrowApp.swift              # Main app entry point
├── ContentView.swift           # Main game view with target, cursor, and shooting
├── SettingsView.swift          # Settings panel for equipment and physics parameters
├── TargetView.swift            # Archery target component
├── AimingCursor.swift          # Draggable aiming cursor component
├── ArrowFlightSimulator.swift  # Physics-based arrow flight simulation engine
├── Info.plist                  # App configuration
└── README.md                   # This file
```

## Requirements

- iOS 14.0 or later
- Xcode 12.0 or later
- Swift 5.3 or later

## How to Use

1. Open Xcode and create a new iOS App project
2. Name it "Target Archery" or your preferred name
3. Choose SwiftUI for the interface and Swift for the language
4. Replace the generated files with the files from this project
5. Build and run on simulator or device

## Gameplay

### Main Screen
- **Drag the crosshair**: Touch and drag the red crosshair to aim at different parts of the target
- **Adjust launch angle**: Use the prominent Launch Angle slider to adjust your shot trajectory
- **Shoot arrow**: Tap the "Shoot Arrow" button to simulate the arrow's flight
  - A green marker appears on target if the arrow hits within the target bounds
  - A yellow marker appears above/below target if the arrow misses high or low
  - A compact results panel slides up from the bottom showing:
    - Warning message (only if off-target or missed)
    - Hit height, time to target
    - Max height, impact angle
    - Tap the panel or X button to dismiss
  - Target remains visible while viewing results
- The cursor provides visual feedback with:
  - Pulsing animation when idle
  - Scale effect when being dragged

### Settings (Gear Icon)
Access the settings panel to configure:

**Range Setup:**
- Initial arrow speed (50-300 ft/s) - bow configuration
- Distance to target (10-100 feet) - range distance

**Arrow Equipment:**
- Arrow weight (250-600 grains) - affects drop and drag

**Advanced Physics:**
- Arrow diameter (0.20-0.35 inches) - cross-sectional area
- Drag coefficient (0.3-0.8) - aerodynamic efficiency

**Presets:**
- Quick-select buttons for light, standard, and heavy arrows

### Physics Simulation

The app uses realistic projectile motion physics with air resistance:

**Physical Constants:**
- Gravity: 32.174 ft/s² (standard Earth gravity)
- Air density: 0.0765 lb/ft³ (sea level)
- Archer height: 5 feet (arrow release point)
- Target center height: 5 feet (aligned with archer)

**Arrow Properties:**
- Weight: 250-600 grains (1 grain = 1/7000 lb)
- Diameter: 0.20-0.35 inches (affects cross-sectional area)
- Drag coefficient: 0.3-0.8 (aerodynamic efficiency)

**Forces Modeled:**
- Gravity: F_g = mg (constant downward force)
- Air Resistance: F_drag = ½ρv²C_dA (opposes motion, proportional to velocity²)
  - ρ = air density
  - v = velocity
  - C_d = drag coefficient
  - A = cross-sectional area

**Simulation Method:**
- Uses numerical integration (Euler method) with 1ms time steps
- Calculates velocity and position at each time step
- Accounts for changing velocity due to drag forces
- More realistic than simple parabolic trajectory

**Key Effects:**
- Heavier arrows are less affected by drag but drop more due to gravity
- Larger diameter arrows experience more air resistance
- Arrows slow down as they fly (velocity is not constant)
- At longer distances, drag significantly affects trajectory

## Future Enhancements

Potential features to add:
- ✅ Shooting mechanism with physics simulation (IMPLEMENTED)
- ✅ Distance variations (IMPLEMENTED)
- Score calculation based on where the arrow lands
- Multiple arrows per round
- Sound effects
- Difficulty levels with moving targets
- Leaderboard and high scores
- Wind effects and air resistance
- Arrow drop visualization/trajectory path display
- Different bow types with varying characteristics
- Save and load simulation presets

## License

Free to use and modify for personal or commercial projects.

