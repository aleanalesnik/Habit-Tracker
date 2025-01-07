import SwiftUI

struct OnboardingCardView: View {
    let card: OnboardingCard
    
    var body: some View {
        VStack {
            Image(systemName: card.illustration)
                .font(.system(size: 100))
                .foregroundStyle(card.color)
            
            Text(card.title)
                .font(.title)
            
            Text(card.subtitle)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.8))
        
        // Create wave
        path.addCurve(
            to: CGPoint(x: 0, y: rect.height * 0.8),
            control1: CGPoint(x: rect.width * 0.75, y: rect.height),
            control2: CGPoint(x: rect.width * 0.25, y: rect.height * 0.6)
        )
        
        path.closeSubpath()
        return path
    }
}

struct GentleBouncingAnimation: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: isAnimating ? -5 : 5)
            .animation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
} 