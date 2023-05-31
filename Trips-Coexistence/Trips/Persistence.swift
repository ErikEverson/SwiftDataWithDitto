/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that sets up the Core Data stack.
*/

import CoreData
import SwiftData

struct PersistenceController {
    let appGroupContainerID = "group.com.example.apple-samplecode.SampleTrips"

    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newTrip = CDTrip(context: viewContext)
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        guard let modelURL = Bundle.main.url(forResource: "Trips", withExtension: "momd") else {
            fatalError("Unable to find Trips data model in the bundle.")
        }
        
        guard let coreDataModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Unable to create the Trips Core Data model.")
        }
        
        container = NSPersistentContainer(name: "Trips", managedObjectModel: coreDataModel)
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            guard let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupContainerID) else {
                fatalError("Shared file container could not be created.")
            }
            
            let url = appGroupContainer.appendingPathComponent("Trips.sqlite")

            if let description = container.persistentStoreDescriptions.first {
                description.url = url
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            }
        }
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
