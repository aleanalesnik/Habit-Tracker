//
//  HabitTrackerApp.swift
//  HabitTracker
//
//  Created by Alea Nalesnik on 1/6/25.
//

import SwiftUI

@main
struct HabitTrackerApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
