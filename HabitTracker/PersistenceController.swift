import CoreData

final class PersistenceController {
    static let shared = PersistenceController()
    
    private init() {
        container = NSPersistentContainer(name: "HabitModel")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    let container: NSPersistentContainer
} 