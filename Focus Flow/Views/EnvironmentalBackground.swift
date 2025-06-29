import SwiftUI

struct EnvironmentalBackground: View {
    let theme: EnvironmentalTheme
    let animated: Bool
    
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: theme.gradientColors,
                startPoint: animated ? .topLeading : .bottomTrailing,
                endPoint: animated ? .bottomTrailing : .topLeading
            )
            
            // Particle overlay
            if theme.hasParticles {
                ParticleEffectView(
                    particleSystem: theme.particleSystem,
                    animationPhase: animationPhase
                )
                .blendMode(.overlay)
                .opacity(0.6)
            }
            
            // Ambient shapes
            if theme.hasAmbientShapes {
                AmbientShapesView(theme: theme)
                    .opacity(0.3)
            }
        }
        .onAppear {
            if animated {
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: true)) {
                    animationPhase = 1
                }
            }
        }
    }
}

// MARK: - Ambient Shapes View

struct AmbientShapesView: View {
    let theme: EnvironmentalTheme
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Large floating shapes
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.gradientColors.randomElement()?.opacity(0.1) ?? Color.clear)
                        .frame(
                            width: CGFloat.random(in: 100...200),
                            height: CGFloat.random(in: 100...200)
                        )
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .rotationEffect(.degrees(rotationAngle + Double(index * 30)))
                        .blur(radius: 20)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}