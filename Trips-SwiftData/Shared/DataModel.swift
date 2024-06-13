/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An actor that provides a SwiftData model container for the whole app and widget,
 and implements actor-isolated tasks like SwiftData history processing.
*/

import SwiftUI
import SwiftData
import DittoSwift

actor DataModel {
    struct TransactionAuthor {
        static let widget = "widget"
    }

    static let shared = DataModel()

    private init() {}

    nonisolated lazy var modelContainer: ModelContainer = {
        let modelContainer: ModelContainer
        do {
            let configuration = DittoStoreConfiguration(name: "Online Playground", schema: Schema([Trip.self, LivingAccommodation.self, BucketListItem.self]), fileURL: try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Testing"))
            modelContainer = try ModelContainer(for: Trip.self, configurations: configuration)
        } catch {
            fatalError("Failed to create the model container: \(error)")
        }
        return modelContainer
    }()
}
