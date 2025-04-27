import SwiftUI

struct BlockCompletionSheet: View {
    @ObservedObject var task: TaskEntity
    @Binding var currentPhase: TimerView.TimerPhase
    let completedTime: Int64
    let onContinue: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    // Animation properties
    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            Color.themeBackground
                .edgesIgnoringSafeArea(.all)
            
            // Confetti animation for focus completion
            if currentPhase == .focus && showConfetti {
                ConfettiView()
                    .edgesIgnoringSafeArea(.all)
                    .allowsHitTesting(false)
            }
            
            VStack(spacing: 30) {
                // Success icon with animation
                ZStack {
                    Circle()
                        .fill(currentPhase == .focus ? Color.themePrimary : Color.green)
                        .frame(width: 120, height: 120)
                        .shadow(color: (currentPhase == .focus ? Color.themePrimary : Color.green).opacity(0.4), radius: 10)
                    
                    Image(systemName: currentPhase == .focus ? "star.fill" : "cup.and.saucer.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                        scale = 1.0
                        opacity = 1.0
                    }
                    
                    // Show confetti if focus session completed
                    if currentPhase == .focus {
                        withAnimation(.easeIn.delay(0.3)) {
                            showConfetti = true
                        }
                    }
                }
                
                // Congratulation text
                Text(currentPhase == .focus ? "Focus Complete!" : "Break Complete!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 30)
                
                // Description
                Text(currentPhase == .focus ? 
                     "Great job staying focused for \(completedTime) minutes!" :
                     "Time to get back to work!")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Stats (only show for focus session)
                if currentPhase == .focus {
                    VStack(spacing: 20) {
                        HStack(spacing: 40) {
                            StatBox(
                                value: "\(completedTime)",
                                label: "Minutes",
                                icon: "clock.fill"
                            )
                            
                            StatBox(
                                value: "\(Int(task.completionPercentage))%",
                                label: "Complete",
                                icon: "chart.bar.fill"
                            )
                        }
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    dismissAndContinue()
                }) {
                    Text(currentPhase == .focus ? "Take a Break" : "Continue Focus")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(currentPhase == .focus ? Color.green : Color.themePrimary)
                        )
                        .padding(.horizontal, 40)
                        .shadow(color: (currentPhase == .focus ? Color.green : Color.themePrimary).opacity(0.3), radius: 10)
                }
                .padding(.bottom, 40)
            }
            .padding()
        }
    }
    
    private func dismissAndContinue() {
        presentationMode.wrappedValue.dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onContinue()
        }
    }
}

// MARK: - Supporting Views

struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color.themePrimary)
                .frame(height: 30)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(width: 100)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.07))
        )
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var confettiPieces = [ConfettiPiece]()
    
    struct ConfettiPiece: Identifiable {
        let id = UUID()
        let color: Color
        let position: CGPoint
        let rotation: Double
        let size: CGFloat
    }
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                Rectangle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size * 0.5)
                    .position(piece.position)
                    .rotationEffect(.degrees(piece.rotation))
            }
        }
        .onAppear {
            // Generate random confetti pieces
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
            
            for _ in 0..<100 {
                let piece = ConfettiPiece(
                    color: colors.randomElement()!,
                    position: CGPoint(
                        x: CGFloat.random(in: 0...screenWidth),
                        y: CGFloat.random(in: 0...screenHeight * 0.7)
                    ),
                    rotation: Double.random(in: 0...360),
                    size: CGFloat.random(in: 5...15)
                )
                confettiPieces.append(piece)
            }
        }
    }
}

//// MARK: - Preview
//struct BlockCompletionSheet_Previews: PreviewProvider {
//    static var previews: some View {
//        let context = PersistenceController.preview.container.viewContext
//        let task = TaskEntity(context: context)
//        task.title = "Sample Task"
//        task.completionPercentage = 75
//        
//        return BlockCompletionSheet(
//            task: task,
//            currentPhase: .constant(.focus),
//            completedTime: 25,
//            onContinue: {}
//        )
//    }
//} 
