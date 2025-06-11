import Foundation
import CoreData

/// Singleton Core Data stack for KSR Cranes app
/// Handles Core Data initialization, contexts, and persistence
final class CoreDataStack {
    
    // MARK: - Singleton
    
    static let shared = CoreDataStack()
    
    // MARK: - Properties
    
    /// The name of the Core Data model file
    private let modelName = "KSRCranes"
    
    /// Main context for UI operations
    lazy var mainContext: NSManagedObjectContext = {
        return self.persistentContainer.viewContext
    }()
    
    /// Background context for heavy operations
    func backgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Core Data Stack
    
    /// Persistent container with migration support
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        
        // Configure for automatic migration
        let description = container.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true
        
        // Set merge policy for main context
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // Log critical error
                print("[CoreDataStack] ❌ Failed to load persistent stores: \(error), \(error.userInfo)")
                
                // In production, you might want to handle this more gracefully
                // For now, we'll crash as this is a critical error
                fatalError("Failed to load Core Data stack: \(error), \(error.userInfo)")
            } else {
                print("[CoreDataStack] ✅ Successfully loaded persistent stores")
                print("[CoreDataStack] 📁 Store URL: \(storeDescription.url?.absoluteString ?? "Unknown")")
            }
        }
        
        return container
    }()
    
    // MARK: - Initialization
    
    private init() {
        // Private initializer to ensure singleton usage
        setupNotificationHandling()
    }
    
    // MARK: - Setup
    
    private func setupNotificationHandling() {
        // Observe Core Data notifications for debugging
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidSave(_:)),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
    }
    
    @objc private func contextDidSave(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext else { return }
        
        // Log save events in debug mode
        #if DEBUG
        let insertedCount = (notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>)?.count ?? 0
        let updatedCount = (notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>)?.count ?? 0
        let deletedCount = (notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>)?.count ?? 0
        
        if insertedCount > 0 || updatedCount > 0 || deletedCount > 0 {
            print("[CoreDataStack] 💾 Context saved - Inserted: \(insertedCount), Updated: \(updatedCount), Deleted: \(deletedCount)")
        }
        #endif
    }
    
    // MARK: - Save Methods
    
    /// Save the main context
    /// - Throws: Core Data save error if save fails
    func save() throws {
        guard mainContext.hasChanges else {
            print("[CoreDataStack] ℹ️ No changes to save in main context")
            return
        }
        
        do {
            try mainContext.save()
            print("[CoreDataStack] ✅ Main context saved successfully")
        } catch {
            print("[CoreDataStack] ❌ Failed to save main context: \(error)")
            throw CoreDataError.saveFailed(error)
        }
    }
    
    /// Save a specific context
    /// - Parameter context: The context to save
    /// - Throws: Core Data save error if save fails
    func save(context: NSManagedObjectContext) throws {
        guard context.hasChanges else {
            print("[CoreDataStack] ℹ️ No changes to save in context")
            return
        }
        
        do {
            try context.save()
            print("[CoreDataStack] ✅ Context saved successfully")
        } catch {
            print("[CoreDataStack] ❌ Failed to save context: \(error)")
            throw CoreDataError.saveFailed(error)
        }
    }
    
    /// Perform a save operation on a background context
    /// - Parameters:
    ///   - block: The block to execute on the background context
    ///   - completion: Optional completion handler called on main thread
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T,
                                  completion: ((Result<T, Error>) -> Void)? = nil) {
        
        persistentContainer.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            do {
                let result = try block(context)
                
                if context.hasChanges {
                    try context.save()
                    print("[CoreDataStack] ✅ Background context saved successfully")
                }
                
                DispatchQueue.main.async {
                    completion?(.success(result))
                }
            } catch {
                print("[CoreDataStack] ❌ Background task failed: \(error)")
                DispatchQueue.main.async {
                    completion?(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Migration Support
    
    /// Check if migration is needed
    /// - Returns: True if the store needs migration
    func needsMigration() -> Bool {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            return false
        }
        
        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: storeURL,
                options: nil
            )
            
            let model = persistentContainer.managedObjectModel
            return !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        } catch {
            print("[CoreDataStack] ⚠️ Could not check migration status: \(error)")
            return false
        }
    }
    
    /// Perform lightweight migration if needed
    /// This is handled automatically by Core Data with the current configuration
    func performMigrationIfNeeded() {
        if needsMigration() {
            print("[CoreDataStack] 🔄 Migration needed and will be performed automatically")
        }
    }
    
    // MARK: - Utility Methods
    
    /// Reset the entire Core Data stack (useful for testing or cache clearing)
    /// WARNING: This will delete all data!
    func resetCoreDataStack() throws {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            throw CoreDataError.storeNotFound
        }
        
        let coordinator = persistentContainer.persistentStoreCoordinator
        
        try coordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
        print("[CoreDataStack] 🗑 Persistent store destroyed")
        
        // Reload the store
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                print("[CoreDataStack] ❌ Failed to reload store after reset: \(error)")
            } else {
                print("[CoreDataStack] ✅ Store reloaded after reset")
            }
        }
    }
    
    /// Get the store URL for debugging purposes
    var storeURL: URL? {
        return persistentContainer.persistentStoreDescriptions.first?.url
    }
    
    /// Get the size of the Core Data store
    var storeSize: Int64? {
        guard let url = storeURL else { return nil }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            print("[CoreDataStack] ⚠️ Could not get store size: \(error)")
            return nil
        }
    }
}

// MARK: - Error Types

enum CoreDataError: LocalizedError {
    case saveFailed(Error)
    case storeNotFound
    case migrationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .storeNotFound:
            return "Core Data store not found"
        case .migrationFailed(let error):
            return "Migration failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Core Data Helpers

extension NSManagedObject {
    /// Check if the object exists in the persistent store
    var existsInStore: Bool {
        return !isDeleted && managedObjectContext != nil && !objectID.isTemporaryID
    }
}

// NOTE: The Core Data model file (KSRCranes.xcdatamodeld) needs to be created in Xcode.
// To create it:
// 1. In Xcode, right-click on the Core/DataPersistence folder
// 2. Select "New File..."
// 3. Choose "Data Model" from the Core Data section
// 4. Name it "KSRCranes"
// 5. This will create KSRCranes.xcdatamodeld