import SwiftUI
import CoreData

struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var currentStep = 0
    @State private var selectedHabits: Set<String> = []
    @State private var showError = false
    @State private var isLoading = false
    
    private let exampleHabits = [
        // Health & Wellness
        "Drink water",
        "Exercise",
        "Meditate",
        "Get 8 hours sleep",
        "Take vitamins",
        "Stretch",
        "Walk 10,000 steps",
        "Eat vegetables",
        
        // Personal Growth
        "Read",
        "Journal",
        "Learn something new",
        "Practice gratitude",
        "Write goals",
        
        // Productivity
        "Plan tomorrow",
        "No phone first hour",
        "Clear inbox",
        "Time block schedule",
        
        // Mindfulness
        "Deep breathing",
        "Morning reflection",
        "Evening review",
        "Digital sunset",
        
        // Lifestyle
        "Make bed",
        "Tidy space",
        "Cook meal",
        "Connect with friend"
    ]
    
    private let cards: [OnboardingCard] = [
        OnboardingCard(
            title: "Build Better Habits",
            subtitle: "Create lasting positive changes in your life with simple daily actions",
            illustration: "figure.mind.and.body",
            color: Color(red: 0.4, green: 0.6, blue: 1.0)
        ),
        OnboardingCard(
            title: "Track Your Progress",
            subtitle: "See your growth over time with beautiful visual insights",
            illustration: "chart.line.uptrend.xyaxis",
            color: Color(red: 1.0, green: 0.6, blue: 0.4)
        ),
        OnboardingCard(
            title: "Stay Motivated",
            subtitle: "Get gentle reminders and celebrate your daily wins",
            illustration: "star.circle.fill",
            color: Color(red: 0.4, green: 0.8, blue: 0.6)
        )
    ]
    
    private let benefits = [
        (
            title: "82% report better consistency",
            description: "Based on users who track habits 5 times per week",
            icon: "chart.line.uptrend.xyaxis.circle.fill"
        ),
        (
            title: "92% achieve their goals faster",
            description: "When using daily habit tracking",
            icon: "flag.circle.fill"
        ),
        (
            title: "95% report increased motivation",
            description: "Through visual progress tracking",
            icon: "sparkles.circle.fill"
        )
    ]
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
            
            Text("Setting up your habits...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
    
    var body: some View {
        if isLoading {
            loadingView
        } else if currentStep == 0 {
            NavigationView {
                VStack {
                    TabView {
                        ForEach(cards) { card in
                            OnboardingCardView(card: card)
                        }
                    }
                    .tabViewStyle(.page)
                    
                    Button("Let's Get Started") {
                        withAnimation { currentStep = 1 }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                .navigationTitle("Welcome")
                .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            NavigationView {
                habitSelectionView
            }
        }
    }
    
    private var habitSelectionView: some View {
        ZStack {
            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: { withAnimation { currentStep = 0 } }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                }
                .padding(.leading, 8)
                
                // Progress bar
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: UIScreen.main.bounds.width * 0.5, height: 3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.2))
                    .padding(.top, 4)
                
                // Rest of the content remains the same
                VStack(spacing: 8) {
                    Text("Choose Your Daily Habits")
                        .font(.title2.bold())
                        .padding(.top, 20)
                    
                    Text("Select at least 2 habits to start your journey")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 32)
                
                // Habits list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(exampleHabits, id: \.self) { habit in
                            HabitOptionButton(
                                habit: habit,
                                isSelected: selectedHabits.contains(habit),
                                action: { toggleHabit(habit) }
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Space for button
                }
            }
            
            // Persistent bottom button with gradient background
            VStack {
                Spacer()
                
                VStack(spacing: 8) {
                    Button(action: completeOnboarding) {
                        Text("Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                selectedHabits.count >= 2 ? 
                                    LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                                    LinearGradient(colors: [.gray, .gray.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                    .disabled(selectedHabits.count < 2)
                    
                    Text("\(selectedHabits.count) habits selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(24)
                .background(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.9), .white],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .edgesIgnoringSafeArea(.bottom)
                )
            }
            .navigationTitle("Choose Habits")
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(Color.white)
    }
    
    // Update HabitOptionButton style
    struct HabitOptionButton: View {
        let habit: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Text(habit)
                        .font(.body)
                        .foregroundColor(isSelected ? .white : .primary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    isSelected ? 
                        LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [.gray.opacity(0.1), .gray.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(12)
            }
            .animation(.spring(duration: 0.3), value: isSelected)
        }
    }
    
    // Add these helper functions
    private func toggleHabit(_ habit: String) {
        if selectedHabits.contains(habit) {
            selectedHabits.remove(habit)
        } else {
            selectedHabits.insert(habit)
        }
    }
    
    private func skipOnboarding() {
        hasCompletedOnboarding = true
    }
    
    private func completeOnboarding() {
        isLoading = true
        
        // Add artificial delay for loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Create habits in Core Data
            for habitName in selectedHabits {
                let habit = CDHabit(context: viewContext)
                habit.id = UUID()
                habit.name = habitName
                habit.createdAt = Date()
                habit.isArchived = false
            }
            
            // Save context and complete onboarding
            do {
                try viewContext.save()
                hasCompletedOnboarding = true
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
} 