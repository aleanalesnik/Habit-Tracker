//
//  ContentView.swift
//  HabitTracker
//
//  Created by Alea Nalesnik on 1/6/25.
//

import SwiftUI
import CoreData

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

struct DateNavigationView: View {
    let dateFormatter: DateFormatter
    let selectedDate: Date
    let isToday: Bool
    let canMoveForward: Bool
    let previousDay: () -> Void
    let nextDay: () -> Void
    
    var body: some View {
        HStack {
            Button(action: previousDay) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.blue)
                    .imageScale(.large)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text(dateFormatter.string(from: selectedDate))
                .font(.title.bold())
                .foregroundColor(isToday ? .blue : .primary)
            
            Spacer()
            
            Button(action: nextDay) {
                Image(systemName: "chevron.right")
                    .foregroundColor(canMoveForward ? .blue : .gray)
                    .imageScale(.large)
                    .frame(width: 44, height: 44)
            }
            .disabled(!canMoveForward)
        }
        .padding(.horizontal)
    }
}

struct HabitsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDHabit.createdAt, ascending: true)],
        predicate: NSPredicate(format: "isArchived == NO"),
        animation: .default)
    private var habits: FetchedResults<CDHabit>
    
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
    
    private func completionsForDate(_ date: Date) -> [CDHabitCompletion] {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return habits.flatMap { habit in
            habit.completionsArray.filter { completion in
                completion.completedAt! >= startOfDay && completion.completedAt! < endOfDay
            }
        }
    }
    
    private var incompleteHabits: [CDHabit] {
        habits.filter { habit in
            !completionsForDate(selectedDate).contains { completion in
                completion.habit == habit
            }
        }
    }
    
    private var completedHabits: [CDHabit] {
        habits.filter { habit in
            completionsForDate(selectedDate).contains { completion in
                completion.habit == habit
            }
        }
    }
    
    private var allHabitsCompleted: Bool {
        !habits.isEmpty && habits.allSatisfy { habit in
            completionsForDate(selectedDate).contains { completion in
                completion.habit == habit
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                DateNavigationView(
                    dateFormatter: dateFormatter,
                    selectedDate: selectedDate,
                    isToday: isToday,
                    canMoveForward: canMoveForward,
                    previousDay: previousDay,
                    nextDay: nextDay
                )
                
                if isToday {
                    HStack {
                        TextField("Enter new habit", text: $newHabitName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        Button(action: addHabit) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.vertical, 15)
                }
                
                List {
                    Section(header: Text("Daily Habits")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    ) {
                        ForEach(incompleteHabits) { habit in
                            HStack {
                                Text(habit.name ?? "")
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        toggleHabitCompletion(habit)
                                    }
                                }) {
                                    Image(systemName: isHabitCompleted(habit) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(isHabitCompleted(habit) ? .green : .gray)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                }
                            }
                        }
                    }
                    
                    if !completedHabits.isEmpty {
                        Section(header: Text("Completed")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        ) {
                            ForEach(completedHabits) { habit in
                                HStack {
                                    Text(habit.name ?? "")
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
                .padding(.top, 10)
                
                Spacer()
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.inline)
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
    
    private func isHabitCompleted(_ habit: CDHabit) -> Bool {
        completionsForDate(selectedDate).contains { $0.habit == habit }
    }
    
    private func toggleHabitCompletion(_ habit: CDHabit) {
        if isHabitCompleted(habit) {
            // Remove completion
            if let completion = completionsForDate(selectedDate).first(where: { $0.habit == habit }) {
                viewContext.delete(completion)
            }
        } else {
            // Add completion
            let completion = CDHabitCompletion(context: viewContext)
            completion.id = UUID()
            completion.completedAt = selectedDate
            completion.habit = habit
            
            if isToday {
                checkAllHabitsCompleted()
            }
        }
        
        saveContext()
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
    
    private var canMoveForward: Bool {
        if let nextDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
            return calendar.isDateInToday(nextDate) || calendar.compare(nextDate, to: Date(), toGranularity: .day) == .orderedAscending
        }
        return false
    }
    
    private func checkAllHabitsCompleted() {
        if allHabitsCompleted {
            showCompletionAlert = true
        }
    }
    
    private func addHabit() {
        let habit = CDHabit(context: viewContext)
        habit.id = UUID()
        habit.name = newHabitName.trimmingCharacters(in: .whitespacesAndNewlines)
        habit.createdAt = Date()
        habit.isArchived = false
        
        saveContext()
        newHabitName = ""
        
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let error = error as NSError
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }
    }
}

struct CompletionRingView: View {
    let progress: Double // 0.0 to 1.0
    let size: CGFloat
    
    private var ringColor: LinearGradient {
        let colors: [Color]
        
        if progress >= 1.0 {
            // Completed - dark green gradient
            colors = [Color(red: 0, green: 0.6, blue: 0), Color(red: 0, green: 0.4, blue: 0)]
        } else if progress >= 0.5 {
            // More than half - medium green gradient
            colors = [Color(red: 0.4, green: 0.8, blue: 0.4), Color(red: 0.2, green: 0.6, blue: 0.2)]
        } else if progress > 0 {
            // Less than half - light red gradient
            colors = [Color(red: 1.0, green: 0.6, blue: 0.6), Color(red: 0.9, green: 0.4, blue: 0.4)]
        } else {
            // No progress - very light gray
            colors = [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]
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
    let viewContext: NSManagedObjectContext
    
    @FetchRequest private var habits: FetchedResults<CDHabit>
    
    init(currentDate: Date, selectedMonth: Binding<Date>, viewContext: NSManagedObjectContext) {
        self.currentDate = currentDate
        self._selectedMonth = selectedMonth
        self.viewContext = viewContext
        
        let request = NSFetchRequest<CDHabit>(entityName: "CDHabit")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDHabit.createdAt, ascending: true)]
        request.predicate = NSPredicate(format: "isArchived == NO")
        _habits = FetchRequest(fetchRequest: request)
    }
    
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
        VStack(spacing: 15) {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                Text(monthString)
                    .font(.title.bold())
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal)
            
            // Day headers
            HStack {
                ForEach(daysInWeek, id: \.self) { day in
                    Text(day)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
                ForEach(daysInMonth, id: \.self) { date in
                    if calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month) {
                        DayCell(date: date, isToday: calendar.isDateInToday(date), habits: habits)
                    } else {
                        DayCell(date: date, isToday: calendar.isDateInToday(date), habits: habits)
                            .opacity(0.3)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
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
    @FetchRequest private var completions: FetchedResults<CDHabitCompletion>
    let habits: FetchedResults<CDHabit>
    
    init(date: Date, isToday: Bool, habits: FetchedResults<CDHabit>) {
        self.date = date
        self.isToday = isToday
        self.habits = habits
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request = NSFetchRequest<CDHabitCompletion>(entityName: "CDHabitCompletion")
        request.predicate = NSPredicate(
            format: "completedAt >= %@ AND completedAt < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDHabitCompletion.completedAt, ascending: true)]
        _completions = FetchRequest(fetchRequest: request)
    }
    
    private var progress: Double {
        guard !habits.isEmpty else { return 0 }
        return Double(completions.count) / Double(habits.count)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isToday ? .blue : .primary)
            
            CompletionRingView(
                progress: progress,
                size: 32
            )
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isToday ? Color.blue : Color.clear, lineWidth: 2)
        )
        .frame(minHeight: 80)
        .contentShape(Rectangle())
    }
}

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedMonth = Date()
    
    var body: some View {
        NavigationView {
            CalendarGridView(currentDate: Date(), selectedMonth: $selectedMonth, viewContext: viewContext)
                .navigationTitle("Calendar")
                .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
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
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabView {
            HabitsView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label("Habits", systemImage: "checkmark.circle.fill")
                }
            
            CalendarView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
