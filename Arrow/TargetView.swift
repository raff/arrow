import SwiftUI

struct TargetView: View {
    // 10-zone archery target (2 zones per color)
    // Scoring: 1-2 (white), 3-4 (black), 5-6 (blue), 7-8 (red), 9-10 (yellow)
    let rings: [(color: Color, size: CGFloat, score: Int)] = [
        (Color.white, 1.0, 1),       // Zone 1 (outer white)
        (Color.white, 0.9, 2),       // Zone 2 (inner white)
        (Color.black, 0.8, 3),       // Zone 3 (outer black)
        (Color.black, 0.7, 4),       // Zone 4 (inner black)
        (Color.blue, 0.6, 5),        // Zone 5 (outer blue)
        (Color.blue, 0.5, 6),        // Zone 6 (inner blue)
        (Color.red, 0.4, 7),         // Zone 7 (outer red)
        (Color.red, 0.3, 8),         // Zone 8 (inner red)
        (Color.yellow, 0.2, 9),      // Zone 9 (outer yellow)
        (Color.yellow, 0.1, 10)      // Zone 10 (center - bullseye)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            
            ZStack {
                // Draw rings from largest to smallest
                ForEach(Array(rings.enumerated()), id: \.offset) { index, ring in
                    Circle()
                        .fill(ring.color)
                        .frame(width: size * ring.size, height: size * ring.size)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 2)
                        )
                }
                
                // Add score zones dividing lines (optional)
                ForEach(0..<4) { i in
                    Rectangle()
                        .fill(Color.black.opacity(0.15))
                        .frame(width: 1, height: size)
                        .rotationEffect(.degrees(Double(i) * 45))
                }
            }
            .frame(width: size, height: size)
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct TargetView_Previews: PreviewProvider {
    static var previews: some View {
        TargetView()
            .frame(width: 340, height: 340)
            .padding()
            .background(Color.gray.opacity(0.2))
    }
}

