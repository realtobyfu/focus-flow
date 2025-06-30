import SwiftUI

struct FloatingClouds: View {
    @State private var cloudOffsets: [CGFloat] = [0, 0, 0]
    @State private var cloudOpacity: [Double] = [0.3, 0.4, 0.3]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Multiple cloud layers for depth
                ForEach(0..<3, id: \.self) { index in
                    CloudShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(cloudOpacity[index]),
                                    Color.white.opacity(cloudOpacity[index] * 0.5)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(
                            width: 150 + CGFloat(index * 30),
                            height: 60 + CGFloat(index * 10)
                        )
                        .position(
                            x: geometry.size.width * CGFloat(index + 1) / 4 + cloudOffsets[index],
                            y: 100 + CGFloat(index * 40)
                        )
                        .blur(radius: CGFloat(index))
                }
                
                // Additional small clouds
                ForEach(0..<2, id: \.self) { index in
                    CloudShape()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 80, height: 30)
                        .position(
                            x: geometry.size.width * 0.7 + cloudOffsets[index] * 0.5,
                            y: 150 + CGFloat(index * 60)
                        )
                        .blur(radius: 2)
                }
            }
        }
        .onAppear {
            // Animate each cloud independently
            for index in 0..<cloudOffsets.count {
                animateCloud(at: index)
            }
        }
    }
    
    private func animateCloud(at index: Int) {
        let duration = Double.random(in: 20...30) + Double(index * 5)
        let distance = CGFloat.random(in: 100...200)
        
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: true)) {
            cloudOffsets[index] = distance
        }
        
        // Subtle opacity animation
        withAnimation(.easeInOut(duration: duration * 0.5).repeatForever(autoreverses: true)) {
            cloudOpacity[index] = cloudOpacity[index] * 1.3
        }
    }
}

// Custom cloud shape
struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Create a fluffy cloud shape using multiple circles
        path.move(to: CGPoint(x: width * 0.2, y: height * 0.5))
        
        // Bottom curve
        path.addCurve(
            to: CGPoint(x: width * 0.8, y: height * 0.5),
            control1: CGPoint(x: width * 0.3, y: height * 0.8),
            control2: CGPoint(x: width * 0.7, y: height * 0.8)
        )
        
        // Right bump
        path.addCurve(
            to: CGPoint(x: width * 0.9, y: height * 0.3),
            control1: CGPoint(x: width * 0.85, y: height * 0.5),
            control2: CGPoint(x: width * 0.9, y: height * 0.4)
        )
        
        // Top right curve
        path.addCurve(
            to: CGPoint(x: width * 0.7, y: height * 0.15),
            control1: CGPoint(x: width * 0.85, y: height * 0.2),
            control2: CGPoint(x: width * 0.75, y: height * 0.15)
        )
        
        // Top middle bump
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.1),
            control1: CGPoint(x: width * 0.65, y: height * 0.1),
            control2: CGPoint(x: width * 0.55, y: height * 0.05)
        )
        
        // Top left curve
        path.addCurve(
            to: CGPoint(x: width * 0.3, y: height * 0.2),
            control1: CGPoint(x: width * 0.45, y: height * 0.1),
            control2: CGPoint(x: width * 0.35, y: height * 0.15)
        )
        
        // Left bump
        path.addCurve(
            to: CGPoint(x: width * 0.15, y: height * 0.35),
            control1: CGPoint(x: width * 0.25, y: height * 0.25),
            control2: CGPoint(x: width * 0.15, y: height * 0.3)
        )
        
        // Close back to start
        path.addCurve(
            to: CGPoint(x: width * 0.2, y: height * 0.5),
            control1: CGPoint(x: width * 0.15, y: height * 0.4),
            control2: CGPoint(x: width * 0.18, y: height * 0.45)
        )
        
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "56CCF2"), Color(hex: "2F80ED")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        FloatingClouds()
    }
}