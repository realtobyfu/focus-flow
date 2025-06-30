import SwiftUI

struct AnimatedSun: View {
    @State private var sunOffset: CGFloat = 100
    @State private var rayRotation: Double = 0
    @State private var glowRadius: CGFloat = 40
    @State private var mistOpacity: Double = 0.6
    
    var body: some View {
        ZStack {
            // Morning mist effect
            ForEach(0..<3, id: \.self) { index in
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(mistOpacity * 0.3),
                                Color.white.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 300 + CGFloat(index * 50), height: 100 + CGFloat(index * 20))
                    .offset(y: 50 + CGFloat(index * 30))
                    .blur(radius: 20)
                    .opacity(mistOpacity)
            }
            
            // Sun with rays
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.yellow.opacity(0.3),
                                Color.orange.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: glowRadius
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 10)
                
                // Sun rays
                ForEach(0..<8, id: \.self) { index in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.yellow.opacity(0.8),
                                    Color.orange.opacity(0.4),
                                    Color.clear
                                ],
                                startPoint: .center,
                                endPoint: .top
                            )
                        )
                        .frame(width: 4, height: 80)
                        .offset(y: -60)
                        .rotationEffect(.degrees(Double(index) * 45 + rayRotation))
                }
                
                // Sun core
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white,
                                Color.yellow,
                                Color.orange
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                    )
            }
            .offset(y: sunOffset)
        }
        .onAppear {
            // Sun rising animation
            withAnimation(.easeOut(duration: 3)) {
                sunOffset = -50
            }
            
            // Ray rotation animation
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                rayRotation = 360
            }
            
            // Glow pulsing animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowRadius = 60
            }
            
            // Mist dissipating animation
            withAnimation(.easeOut(duration: 5).delay(2)) {
                mistOpacity = 0.2
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "F8B500"), Color(hex: "fceabb")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        AnimatedSun()
    }
}