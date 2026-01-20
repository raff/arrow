import SwiftUI

struct AimingCursor: View {
    let isDragging: Bool
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            // Outer circle that pulses
            Circle()
                .stroke(Color.red, lineWidth: 2)
                .frame(width: 40, height: 40)
                .scaleEffect(pulse ? 1.2 : 1.0)
                .opacity(pulse ? 0.5 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: pulse
                )
            
            // Inner circle
            Circle()
                .fill(Color.red.opacity(0.3))
                .frame(width: 30, height: 30)
            
            // Crosshair lines
            Group {
                // Vertical line
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 2, height: 50)
                
                // Horizontal line
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 50, height: 2)
            }
            
            // Center dot
            Circle()
                .fill(Color.red)
                .frame(width: 4, height: 4)
            
            // White outline for better visibility
            Circle()
                .stroke(Color.white, lineWidth: 1.5)
                .frame(width: 40, height: 40)
        }
        .scaleEffect(isDragging ? 1.2 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
        .onAppear {
            pulse = true
        }
    }
}

struct AimingCursor_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.3)
            AimingCursor(isDragging: false)
        }
    }
}

