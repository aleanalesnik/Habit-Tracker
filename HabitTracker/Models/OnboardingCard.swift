import SwiftUI

struct OnboardingCard: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let illustration: String
    let color: Color
} 