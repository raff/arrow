# Arrow
A SwiftUI-based iOS application featuring a realistic target archery simulation and competition scorer with motion-based aiming.

## Features

### 🎯 Realistic Archery Target
- Multi-colored target rings following standard archery target design
  - White outer ring, Black ring, Blue ring, Red ring, Yellow ring
  - Yellow center bullseye with red dot
- Configurable target sizes: **40cm, 80cm, or 122cm** (tournament standard)
- 10-ring scoring system (10 = center bullseye, 0 = miss)
- Visual markers for all shots:
  - **Current set arrows**: Numbered colored dots (1, 2, 3...)
  - **Previous set arrows**: Black dots (arrow holes)
  - Arrow hole size scales with arrow diameter for realism

### 📱 Motion-Based Aiming
- **Accelerometer control**: Use your phone's tilt to aim
  - Tilt up/down to adjust elevation
  - Tilt left/right to adjust windage
  - Real-time visual feedback showing predicted hit location
- **Calibration system**: Tap the scope icon to zero the cursor at your current position
- **Adjustable sensitivity**: Configure motion sensitivity and dampening in settings
- **Aiming cursor**: Animated crosshair that tracks your phone's angle

### 🏹 Arrow Flight Simulation
- **Physics-based projectile motion** with realistic air resistance
- Adjustable parameters:
  - Initial speed (50-300 ft/s, default 150 ft/s)
  - Distance to target (10-300 feet / 3-90 meters)
  - Arrow weight (250-600 grains, default 400)
  - Arrow diameter (3-11 mm, default 7 mm)
  - Draw length (24-32 inches, default 28 inches)
  - Drag coefficient (0.3-0.8, default 0.55)
- Real-time calculation accounting for:
  - Arrow mass and cross-sectional area
  - Quadratic air resistance (drag forces)
  - Gravitational drop
  - Release time based on draw length

### 🎮 Multiple Control Methods
- **Volume Button / Selfie Remote**: Press volume up to shoot arrows or advance between sets
- **Tap to Shoot**: Tap anywhere on the target area to release an arrow
- **Remote Control Compatible**: Works with Bluetooth camera remotes

### 🏆 Competition Mode
- **Full competition scoring** with 10 sets
- **Automatic set sizing**:
  - Distances < 50m: 3 arrows per set
  - Distances ≥ 50m: 6 arrows per set
- **Complete scorecard** with:
  - Individual arrow scores per set
  - Set totals
  - Running totals after each set
  - Grand total score
  - Average per arrow and per set
- **Set completion modal**: Automatic scorecard display after each set
- **Competition summary**: Trophy screen when all sets are complete

### 🎚️ Distance Presets
- **Meter presets** (tournament): 18m, 25m, 30m, 50m, 60m, 70m, 90m
- **Yard presets** (field archery): 20yd, 30yd, 40yd, 50yd, 60yd
- Automatic target size recommendations based on distance

### 🎨 User Interface
- **Splash screen** with static launch screen (no white flash)
- Beautiful gradient background
- Clean, professional competition-style display
- **Real-time motion feedback**:
  - Elevation display (degrees)
  - Windage display (degrees)
  - Remote trigger indicator
- Settings accessible via gear icon
- Smooth animations using SwiftUI

### 🔊 Audio & Haptics
- **Sound effects**:
  - Arrow release sound
  - Hit sound (successful shot)
  - Miss sound
- **Haptic feedback**:
  - Light haptic on release
  - Medium/heavy haptic on hit (intensity varies with score)
- **Toggle controls**: Enable/disable audio and haptics independently in settings

### 💾 Settings Persistence
- All settings automatically saved using `UserDefaults`
- Settings persist across app launches:
  - Arrow specifications (speed, weight, diameter, draw length)
  - Target configuration (distance, size)
  - Physics parameters (drag coefficient)
  - Motion control settings (sensitivity, dampening)
  - Audio and haptic preferences

## Project Structure

```
Arrow/
├── Arrow/
│   ├── ArrowApp.swift              # Main app entry point with splash screen
│   ├── ContentView.swift           # Main competition view with motion control
│   ├── SettingsView.swift          # Settings panel for all parameters
│   ├── TargetView.swift            # Archery target component (10-ring design)
│   ├── AimingCursor.swift          # Motion-controlled aiming cursor
│   ├── ArrowFlightSimulator.swift  # Physics-based flight simulation engine
│   ├── MotionManager.swift         # Accelerometer motion tracking and calibration
│   ├── SoundManager.swift          # Audio effects and haptic feedback
│   ├── SplashScreenView.swift      # App splash screen
│   ├── Defaults.swift              # Default configuration values
│   ├── Launch Screen.storyboard    # Launch screen configuration
│   └── Assets.xcassets/            # App icons and color assets
├── Arrow.xcodeproj/                # Xcode project file
├── README.md                       # This file
└── LICENSE                         # License information
```

## Requirements

- **iOS 15.0 or later** (for `@AppStorage` and modern SwiftUI features)
- **Xcode 13.0 or later**
- **Swift 5.5 or later**
- **Device with accelerometer** (for motion-based aiming)
- **Optional**: Bluetooth camera remote or wired volume button remote for hands-free shooting

## How to Use

### Getting Started
1. **Launch the app** - Splash screen appears briefly
2. **Hold your phone vertically** in portrait orientation
3. **Tap the scope icon** to calibrate your aiming position (sets current phone angle as center)
4. **Tilt your phone** to aim the cursor at different parts of the target
5. **Shoot**: Tap the screen OR press your volume up button (or Bluetooth remote)

### Main Screen
- **Motion aiming**: Tilt your phone to move the cursor
  - Up/down: Adjusts elevation (vertical aim)
  - Left/right: Adjusts windage (horizontal aim)
  - Cursor shows predicted hit location based on physics simulation
- **Calibrate button** (scope icon): Resets the center position to your current phone angle
- **Score display**: Shows current set progress and total score
  - Current set scorecard with all arrow scores
  - Set number (e.g., "Set 3 of 10")
  - Total score running total
- **Shoot arrows**:
  - Tap anywhere on target area
  - Press volume up button
  - Use Bluetooth camera remote
- **Arrow markers**:
  - **Colored numbered dots**: Current set arrows (shows arrow number in set)
  - **Black dots**: Previous set arrows (permanent record)
  - Score-based colors: Green (7-10), Yellow (4-6), Orange (1-3), Gray (0 miss)

### Between Sets
- After completing a set (3 or 6 arrows), a **scorecard modal** appears showing:
  - Full competition scorecard with all sets
  - Individual arrow scores
  - Set totals and running totals
  - Your current progress
- **Continue to next set**:
  - Tap the "Continue to Set X" button
  - Tap anywhere on the scorecard
  - Press volume up button
- Current set arrows become black dots, ready for next set

### Competition Complete
- After 10 sets, see your **final score** and statistics
- **View Scorecard** button: Review all your sets and scores
- **Start New Competition** button: Clear scores and begin fresh
- **Scorecard details**:
  - All 10 sets with individual arrow scores
  - Running totals after each set
  - Summary statistics (total score, average per arrow, average per set)

### Settings (Gear Icon)
Access comprehensive settings to configure:

**Audio & Haptics:**
- Sound effects (release, hit, miss sounds)
- Haptic feedback (vibration on shots)

**Motion Control:**
- Angle sensitivity (0.5x - 5.0x) - how much tilt affects cursor
- Dampening/smoothing (5% - 50%) - movement smoothness

**Range Setup:**
- Initial speed (50-300 ft/s) - bow power
- Distance to target (10-300 feet) - with preset buttons
- Target face size (40cm, 80cm, 122cm) - tournament standard

**Arrow Equipment:**
- Arrow weight (250-600 grains) - affects trajectory
- Draw length (24-32 inches) - affects release timing

**Advanced Physics:**
- Arrow diameter (3-11 mm) - affects air resistance and visual size
- Drag coefficient (0.3-0.8) - aerodynamic efficiency

**Distance Presets:**
- Meters: 18m, 25m, 30m, 50m, 60m, 70m, 90m
- Yards: 20yd, 30yd, 40yd, 50yd, 60yd
- Auto-sets appropriate target size

**Arrow Presets:**
- Ultra Light Arrow (350gr, 28in, 4.2mm)
- Standard Arrow (400gr, 28in, 7mm)
- Heavy Indoor Arrow (500gr, 30in, 9mm)

### Physics Simulation

The app uses realistic projectile motion physics with comprehensive air resistance modeling:

**Physical Constants:**
- Gravity: 32.174 ft/s² (standard Earth gravity)
- Air density: 0.0765 lb/ft³ (sea level conditions)
- Archer height: 5 feet (arrow release point)
- Target center height: 5 feet (aligned with archer)

**Arrow Properties:**
- Weight: 250-600 grains (1 grain = 1/7000 lb)
- Diameter: 3-11 mm (affects cross-sectional area and visual display)
- Draw length: 24-32 inches (affects release timing)
- Drag coefficient: 0.3-0.8 (aerodynamic efficiency)

**Forces Modeled:**
- **Gravity**: F_g = mg (constant downward force)
- **Air Resistance**: F_drag = ½ρv²C_dA (opposes motion, proportional to velocity²)
  - ρ = air density
  - v = instantaneous velocity
  - C_d = drag coefficient (arrow aerodynamics)
  - A = cross-sectional area (based on arrow diameter)

**Simulation Method:**
- Numerical integration (Euler method) with 1ms time steps
- Real-time calculation of velocity and position at each time step
- Accounts for:
  - Changing velocity due to drag forces
  - Release time based on draw length (arrow must clear bow)
  - Launch angle from phone tilt (accelerometer-based)
  - Windage from phone roll

**Key Effects:**
- **Heavier arrows**: Less affected by drag, but drop more due to gravity
- **Larger diameter arrows**: Experience more air resistance
- **Velocity decay**: Arrows slow down as they fly (not constant velocity)
- **Distance impact**: At longer distances, drag significantly affects trajectory
- **Realistic scoring**: Arrow diameter affects whether edge touches higher scoring ring (benefit of the doubt)

## Completed Features

- ✅ Physics-based arrow flight simulation with air resistance
- ✅ Distance variations with tournament presets
- ✅ 10-ring score calculation (WA standard)
- ✅ Full competition mode (10 sets, 3 or 6 arrows per set)
- ✅ Motion-based aiming using accelerometer
- ✅ Sound effects and haptic feedback
- ✅ Complete scorecard system with running totals
- ✅ Settings persistence across app launches
- ✅ Volume button / remote control support
- ✅ Target size configuration (40cm, 80cm, 122cm)
- ✅ Arrow hole size scaling based on arrow diameter
- ✅ Launch screen and splash screen

## Potential Future Enhancements

- Export scorecard to PDF or share as image
- Competition history / past scores database
- Leaderboard and personal best tracking
- Wind simulation (crosswind affects horizontal trajectory)
- Arrow trajectory path visualization (show flight path)
- Save/load custom equipment presets by name
- Multiple archer profiles
- Training mode with target zones highlighted
- Sight marks calculator based on your setup
- Integration with Apple Watch for remote control
- Landscape mode support for iPad

## Technical Implementation

**SwiftUI Framework:**
- Modern declarative UI with state management
- `@State`, `@StateObject`, `@AppStorage` for reactive data flow
- Sheet presentations for settings and scorecard
- Smooth animations and transitions

**Core Motion:**
- `CMMotionManager` for accelerometer data
- Device attitude tracking using `.xArbitraryCorrectedZVertical` reference frame
- Low-pass filter for smooth cursor movement
- Calibration system for flexible device positioning

**AVFoundation & MediaPlayer:**
- Volume button monitoring using `AVAudioSession`
- `MPVolumeView` for programmatic volume control
- Automatic volume restoration after button press

**UserDefaults Persistence:**
- `@AppStorage` property wrapper for automatic persistence
- All settings saved and restored across app launches
- Custom `UserDefaults` integration for `@Published` properties

**Physics Engine:**
- Custom numerical integration (Euler method)
- Real-time trajectory calculation
- Quadratic drag force modeling
- Configurable physical parameters

## Tips for Best Experience

**Aiming:**
1. Hold your phone comfortably in portrait orientation
2. Tap the **scope icon** to calibrate before each competition
3. Make small, controlled tilts - the cursor is sensitive
4. Adjust sensitivity in settings if cursor moves too much or too little
5. Increase dampening for smoother (but slower) cursor movement

**Shooting:**
1. Use a **Bluetooth camera remote** or **wired remote** for most realistic experience
2. Volume up button works great for hands-free shooting
3. Hold phone steady while shooting - motion affects the shot

**Competition Setup:**
1. Start with **18m distance, 40cm target** (standard indoor setup)
2. Configure your **arrow weight and speed** to match your equipment
3. Test a few shots to verify settings feel realistic
4. Use **distance presets** for quick tournament standard distances

**Scoring:**
1. Arrow diameter affects scoring - larger arrows get "benefit of the doubt"
2. Review scorecard after each set to track progress
3. Competition automatically completes after 10 sets
4. Clear scores only when starting a new distance or target size

## License

Free to use and modify for personal projects. Not for commercial use without permission.
See LICENSE file for details.
