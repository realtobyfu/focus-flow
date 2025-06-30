import SwiftUI

struct MoonPhase: View {
    @State private var moonGlow: CGFloat = 30
    @State private var starOpacity: Double = 0
    @State private var craterOffset: CGFloat = 0
    
    // Calculate current moon phase (simplified)
    private var moonPhaseAngle: Double {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())
        // Simple approximation: full cycle every 30 days
        return Double(day) / 30.0 * 360.0
    }
    
    var body: some View {
        ZStack {
            // Stars background
            ForEach(0..<20, id: \.self) { index in
                Star()
                    .fill(Color.white)
                    .frame(width: CGFloat.random(in: 2...4), height: CGFloat.random(in: 2...4))
                    .position(
                        x: CGFloat.random(in: 50...350),
                        y: CGFloat.random(in: 50...250)
                    )
                    .opacity(starOpacity)
                    .animation(.easeIn(duration: 0.5).delay(Double(index) * 0.1), value: starOpacity)
            }
            
            // Moon
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.blue.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: moonGlow
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 10)
                
                // Moon surface
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.95, green: 0.95, blue: 0.9),
                                Color(red: 0.85, green: 0.85, blue: 0.8)
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        // Craters
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 15, height: 15)
                                .offset(x: -10 + craterOffset, y: -15)
                            
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 10, height: 10)
                                .offset(x: 15, y: 10 - craterOffset)
                            
                            Circle()
                                .fill(Color.gray.opacity(0.25))
                                .frame(width: 8, height: 8)
                                .offset(x: -5, y: 20 + craterOffset)
                        }
                    )
                    .mask(
                        // Moon phase mask
                        GeometryReader { geometry in
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                
                                // Phase shadow
                                Ellipse()
                                    .fill(Color.black)
                                    .scaleEffect(x: abs(cos(moonPhaseAngle * .pi / 180)), y: 1)
                                    .offset(x: sin(moonPhaseAngle * .pi / 180) * 40)
                            }
                        }
                    )
                    .shadow(color: Color.white.opacity(0.5), radius: 10)
            }
        }
        .onAppear {
            // Stars appearing animation
            withAnimation(.easeIn(duration: 2)) {
                starOpacity = 1
            }
            
            // Moon glow pulsing
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                moonGlow = 60
            }
            
            // Subtle crater movement
            withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                craterOffset = 2
            }
        }
    }
}

// Star shape
struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = rect.width / 2
        let rc = r * 0.4
        let rn = r * 0.2
        
        var path = Path()
        
        for i in 0..<5 {
            let angle = (360.0 / 5) * Double(i) * .pi / 180
            let angleN = angle + (360.0 / 10) * .pi / 180
            
            let pt = CGPoint(
                x: center.x + CGFloat(cos(angle)) * r,
                y: center.y + CGFloat(sin(angle)) * r
            )
            
            let ptn = CGPoint(
                x: center.x + CGFloat(cos(angleN)) * rn,
                y: center.y + CGFloat(sin(angleN)) * rn
            )
            
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
            
            path.addLine(to: ptn)
        }
        
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "141E30"), Color(hex: "243B55")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        MoonPhase()
    }
}