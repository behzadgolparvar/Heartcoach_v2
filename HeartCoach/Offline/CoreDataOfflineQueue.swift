import Foundation
import CoreData
import HeartRateCoachCore

final class CoreDataOfflineQueue: OfflineSessionQueueProtocol {

    private let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "OfflineQueue")

        // Apply file protection — store encrypted while device is locked
        if let url = container.persistentStoreDescriptions.first?.url {
            container.persistentStoreDescriptions.first?.setOption(
                FileProtectionType.complete as NSObject,
                forKey: NSPersistentStoreFileProtectionKey
            )
            _ = url // suppress unused warning
        }

        container.loadPersistentStores { _, error in
            if let error {
                // Core Data failure on first launch is unrecoverable — log and continue without queue
                print("[OfflineQueue] Failed to load persistent store: \(error)")
            }
        }
    }

    func enqueue(_ session: Session) throws {
        let context = container.newBackgroundContext()
        try context.performAndWait {
            let entity = NSEntityDescription.insertNewObject(
                forEntityName: "PendingSession", into: context
            )
            entity.setValue(session.id, forKey: "id")
            entity.setValue(try JSONEncoder().encode(session), forKey: "payload")
            entity.setValue(Date(), forKey: "createdAt")
            try context.save()
        }
    }

    func pendingSessions() throws -> [Session] {
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "PendingSession")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        let results = try context.fetch(request)
        return results.compactMap { obj in
            guard let data = obj.value(forKey: "payload") as? Data else { return nil }
            return try? JSONDecoder().decode(Session.self, from: data)
        }
    }

    func markSynced(id: String) throws {
        let context = container.newBackgroundContext()
        try context.performAndWait {
            let request = NSFetchRequest<NSManagedObject>(entityName: "PendingSession")
            request.predicate = NSPredicate(format: "id == %@", id)
            let results = try context.fetch(request)
            results.forEach { context.delete($0) }
            try context.save()
        }
    }
}
