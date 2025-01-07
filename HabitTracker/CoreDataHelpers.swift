import Foundation
import CoreData

extension CDHabit {
    var completionsArray: [CDHabitCompletion] {
        let set = completions as? Set<CDHabitCompletion> ?? []
        return Array(set).sorted { $0.completedAt ?? Date() < $1.completedAt ?? Date() }
    }
} 