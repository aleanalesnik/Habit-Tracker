//
//  ContentView.swift
//  HabitTracker
//
//  Created by Alea Nalesnik on 1/6/25.
//

import SwiftUI

struct HabitCompletion: Identifiable {
    let id = UUID()
    let habitId: UUID
    let date: Date
}

struct Habit: Identifiable {
    let id = UUID()
    let name: String
    var isCompleted: Bool
}

struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .padding()
            .background(Color.green.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.bottom, 20)
    }
}

struct HabitsView: View {
    @State private var habits: [Habit] = []
    @State private var habitCompletions: [HabitCompletion] = []
    @State private var newHabitName = ""
    @State private var showToast = false
    @State private var showCompletionAlert = false
    @State private var selectedDate = Date()
    
    private let calendar = Calendar.current
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(selectedDate)
    }
    
    var incompleteHabits: [Habit] {
        habits.filter { habit in
            !isHabitCompleted(habit, on: selectedDate)
        }
    }
    
    var completedHabits: [Habit] {
        habits.filter { habit in
            isHabitCompleted(habit, on: selectedDate)
        }
    }
    
    var allHabitsCompleted: Bool {
        !habits.isEmpty && habits.allSatisfy { isHabitCompleted($0, on: selectedDate) }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Date Navigation
                HStack {
                    Button(action: previousDay) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text(dateFormatter.string(from: selectedDate))
                        .font(.headline)
                        .foregroundColor(isToday ? .blue : .primary)
                    
                    Spacer()
                    
                    Button(action: nextDay) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(canMoveForward ? .blue : .gray)
                    }
                    .disabled(!canMoveForward)
                }
                .padding(.horizontal)
                
                if isToday {
                    HStack {
                        TextField("Enter new habit", text: $newHabitName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.leading)
                        
                        Button(action: addHabit) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                
                List {
                    Section(header: Text("Daily Habits")) {
                        ForEach(habits.filter { !isHabitCompleted($0, on: selectedDate) }) { habit in
                            HStack {
                                Text(habit.name)
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        toggleHabitCompletion(habit)
                                    }
                                }) {
                                    Image(systemName: isHabitCompleted(habit, on: selectedDate) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(isHabitCompleted(habit, on: selectedDate) ? .green : .gray)
                                        .font(.title2)
                                }
                            }
                        }
                    }
                    
                    if !completedHabits.isEmpty {
                        Section(header: Text("Completed")) {
                            ForEach(habits.filter { isHabitCompleted($0, on: selectedDate) }) { habit in
                                HStack {
                                    Text(habit.name)
                                    Spacer()
                                    Button(action: {
                                        withAnimation {
                                            toggleHabitCompletion(habit)
                                        }
                                    }) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.title2)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Habit Tracker")
            .overlay(
                Group {
                    if showToast {
                        ToastView(message: "Habit added successfully!")
                            .transition(.move(edge: .bottom))
                            .animation(.easeInOut, value: showToast)
                    }
                }, alignment: .bottom
            )
            .alert("Congratulations! 🎉", isPresented: $showCompletionAlert) {
                Button("Keep it up!", role: .cancel) { }
            } message: {
                Text("You've completed all your habits for today! Amazing job staying committed to your goals!")
            }
        }
    }
    
    private func isHabitCompleted(_ habit: Habit, on date: Date) -> Bool {
        habitCompletions.contains { completion in
            completion.habitId == habit.id && calendar.isDate(completion.date, inSameDayAs: date)
        }
    }
    
    private func toggleHabitCompletion(_ habit: Habit) {
        if isHabitCompleted(habit, on: selectedDate) {
            // Remove completion
            habitCompletions.removeAll { completion in
                completion.habitId == habit.id && calendar.isDate(completion.date, inSameDayAs: selectedDate)
            }
        } else {
            // Add completion
            habitCompletions.append(HabitCompletion(habitId: habit.id, date: selectedDate))
            if isToday {
                checkAllHabitsCompleted()
            }
        }
    }
    
    private func previousDay() {
        withAnimation {
            if let newDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
                selectedDate = newDate
            }
        }
    }
    
    private func nextDay() {
        withAnimation {
            if let newDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
                if calendar.isDateInToday(newDate) || calendar.compare(newDate, to: Date(), toGranularity: .day) == .orderedAscending {
                    selectedDate = newDate
                }
            }
        }
    }
    
    private func checkAllHabitsCompleted() {
        if allHabitsCompleted {
            showCompletionAlert = true
        }
    }
    
    private func addHabit() {
        let habit = newHabitName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !habit.isEmpty else { return }
        
        habits.append(Habit(name: habit, isCompleted: false))
        newHabitName = ""
        
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }
    
    private var canMoveForward: Bool {
        if let nextDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
            return calendar.isDateInToday(nextDate) || calendar.compare(nextDate, to: Date(), toGranularity: .day) == .orderedAscending
        }
        return false
    }
}

struct CompletionRingView: View {
    let progress: Double // 0.0 to 1.0
    let size: CGFloat
    
    private var ringColor: LinearGradient {
        let colors: [Color]
        
        if progress >= 1.0 {
            // Completed - bright green gradient
            colors = [.green, .green.opacity(0.8)]
        } else if progress >= 0.5 {
            // More than half - yellow gradient
            colors = [.yellow, .yellow.opacity(0.8)]
        } else {
            // Less than half - red gradient
            colors = [.red, .red.opacity(0.8)]
        }
        
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 2)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: progress >= 1.0 ? 3 : 2, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .scaleEffect(progress >= 1.0 ? 1.1 : 1.0) // Make completed rings slightly larger
    }
}

struct CalendarGridView: View {
    let currentDate: Date
    @Binding var selectedMonth: Date
    
    private let calendar = Calendar.current
    private let daysInWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    private var monthString: String {
        selectedMonth.formatted(.dateTime.month(.wide).year())
    }
    
    private var daysInMonth: [Date] {
        let interval = calendar.dateInterval(of: .month, for: selectedMonth)!
        let firstDay = interval.start
        
        // Get the first day of the week containing the first day of the month
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let offsetDays = firstWeekday - calendar.firstWeekday
        let startDate = calendar.date(byAdding: .day, value: -offsetDays, to: firstDay)!
        
        var dates: [Date] = []
        let numberOfDays = 42 // 6 weeks × 7 days
        
        for day in 0..<numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day, to: startDate) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(monthString)
                    .font(.title2.bold())
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Day headers
            HStack {
                ForEach(daysInWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(daysInMonth, id: \.self) { date in
                    if calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month) {
                        DayCell(date: date, isToday: calendar.isDateInToday(date))
                    } else {
                        DayCell(date: date, isToday: calendar.isDateInToday(date))
                            .opacity(0.3)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 5)
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
}

struct DayCell: View {
    let date: Date
    let isToday: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack {
            Text("\(calendar.component(.day, from: date))")
                .font(.callout)
                .foregroundColor(isToday ? .blue : .primary)
            
            // For demo purposes, showing random progress
            CompletionRingView(
                progress: isToday ? 0.7 : Double.random(in: 0...1),
                size: 24
            )
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday ? Color.blue : Color.clear, lineWidth: 1)
        )
        .frame(height: 60)
    }
}

struct CalendarView: View {
    @State private var selectedMonth = Date()
    
    var body: some View {
        NavigationView {
            CalendarGridView(currentDate: Date(), selectedMonth: $selectedMonth)
                .navigationTitle("Calendar")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Helper extension for calendar date generation
extension Calendar {
    func generateDates(for dateInterval: DateInterval, matching components: DateComponents = DateComponents()) -> [Date] {
        var dates = [Date]()
        dates.append(dateInterval.start)
        
        enumerateDates(
            startingAfter: dateInterval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            guard let date = date else { return }
            
            guard date < dateInterval.end else {
                stop = true
                return
            }
            
            dates.append(date)
        }
        
        return dates
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            HabitsView()
                .tabItem {
                    Label("Habits", systemImage: "checkmark.circle.fill")
                }
            
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
        }
    }
}

#Preview {
    ContentView()
}
