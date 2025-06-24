import SwiftUI

struct ParticleEffectView: View {
    let particleSystem: ParticleSystem
    let animationPhase: Double

    @State private var particles: [Particle] = []

    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var opacity: Double
        var size: CGFloat
        var velocity: CGVector
        var lifetime: Double
        var rotation: Double
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ParticleView(
                        particle: particle,
                        type: particleSystem.type
                    )
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                startAnimation()
            }
        }
    }

    private func generateParticles(in size: CGSize) {
        particles = (0..<particleSystem.density.particleCount).map { _ in
            createParticle(in: size)
        }
    }

    private func createParticle(in size: CGSize) -> Particle {
        switch particleSystem.type {
        case .stars:
            return Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                opacity: Double.random(in: 0.3...1.0),
                size: CGFloat.random(in: 1...3),
                velocity: .zero,
                lifetime: Double.random(in: 3...6),
                rotation: 0
            )
        case .aurora:
            return Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height * 0.5)
                ),
                opacity: Double.random(in: 0.1...0.3),
                size: CGFloat.random(in: 100...200),
                velocity: CGVector(
                    dx: CGFloat.random(in: -20...20),
                    dy: 0
                ),
                lifetime: Double.random(in: 10...20),
                rotation: Double.random(in: -45...45)
            )
        case .dust:
            return Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                opacity: Double.random(in: 0.3...0.6),
                size: CGFloat.random(in: 1...2),
                velocity: CGVector(
                    dx: CGFloat.random(in: -5...5),
                    dy: CGFloat.random(in: 5...10)
                ),
                lifetime: Double.random(in: 5...10),
                rotation: 0
            )
        case .energy:
            return Particle(
                position: CGPoint(
                    x: size.width / 2,
                    y: size.height / 2
                ),
                opacity: Double.random(in: 0.6...1.0),
                size: CGFloat.random(in: 5...15),
                velocity: CGVector(
                    dx: CGFloat.random(in: -50...50),
                    dy: CGFloat.random(in: -50...50)
                ),
                lifetime: Double.random(in: 1...3),
                rotation: Double.random(in: 0...360)
            )
        case .fireflies:
            return Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: size.height * 0.3...size.height)
                ),
                opacity: 0,
                size: CGFloat.random(in: 3...5),
                velocity: CGVector(
                    dx: CGFloat.random(in: -10...10),
                    dy: CGFloat.random(in: -5...5)
                ),
                lifetime: Double.random(in: 5...10),
                rotation: 0
            )
        default:
            return Particle(
                position: .zero,
                opacity: 0,
                size: 0,
                velocity: .zero,
                lifetime: 0,
                rotation: 0
            )
        }
    }

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            updateParticles()
        }
    }

    private func updateParticles() {
        for i in particles.indices {
            particles[i].position.x += particles[i].velocity.dx * 0.1
            particles[i].position.y += particles[i].velocity.dy * 0.1
            particles[i].lifetime -= 0.05

            if particleSystem.type == .fireflies {
                particles[i].opacity = sin(particles[i].lifetime) * 0.8
            }

            if particles[i].lifetime <= 0 {
                particles[i] = createParticle(in: UIScreen.main.bounds.size)
            }
        }
    }
}

struct ParticleView: View {
    let particle: ParticleEffectView.Particle
    let type: ParticleSystem.ParticleType

    var body: some View {
        Group {
            switch type {
            case .stars:
                Image(systemName: "star.fill")
                    .font(.system(size: particle.size))
                    .foregroundColor(.white)
                    .opacity(particle.opacity)
                    .position(particle.position)
                    .blur(radius: particle.size < 2 ? 0.5 : 0)

            case .aurora:
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.3),
                                Color.blue.opacity(0.2),
                                Color.purple.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: particle.size, height: particle.size * 0.3)
                    .blur(radius: 20)
                    .opacity(particle.opacity)
                    .position(particle.position)
                    .rotationEffect(.degrees(particle.rotation))

            case .dust:
                Circle()
                    .fill(Color.gray)
                    .frame(width: particle.size, height: particle.size)
                    .opacity(particle.opacity)
                    .position(particle.position)

            case .energy:
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white,
                                Color.blue.opacity(0.8),
                                Color.purple.opacity(0.5)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: particle.size / 2
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .blur(radius: 2)
                    .opacity(particle.opacity)
                    .position(particle.position)
                    .rotationEffect(.degrees(particle.rotation))

            case .fireflies:
                Circle()
                    .fill(Color.yellow)
                    .frame(width: particle.size, height: particle.size)
                    .blur(radius: 1)
                    .opacity(particle.opacity)
                    .position(particle.position)
                    .shadow(color: .yellow, radius: particle.size)

            default:
                EmptyView()
            }
        }
    }
} 