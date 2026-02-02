import SwiftUI

struct TargetView: View {
    let targetStyle: TargetStyle

    private var rings: [(color: Color, size: CGFloat, score: Int)] {
        let ringCount = targetStyle.ringCount
        let step = 1.0 / CGFloat(ringCount)
        let colors: [Color]

        switch targetStyle {
        case .targetArchery:
            colors = [
                Color.white, Color.white,
                Color.black, Color.black,
                Color.blue, Color.blue,
                Color.red, Color.red,
                Color.yellow, Color.yellow
            ]
        case .fieldArchery:
            colors = [
                Color.black, Color.black,
                Color.black, Color.black,
                Color.yellow, Color.yellow
            ]
        }

        return (0..<ringCount).map { index in
            let size = 1.0 - (CGFloat(index) * step)
            let score = ringCount - index
            return (colors[index], size, score)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            
            ZStack {
                // Draw rings from largest to smallest
                ForEach(Array(rings.enumerated()), id: \.offset) { _, ring in
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
        TargetView(targetStyle: .targetArchery)
            .frame(width: 340, height: 340)
            .padding()
            .background(Color.gray.opacity(0.2))
    }
}
