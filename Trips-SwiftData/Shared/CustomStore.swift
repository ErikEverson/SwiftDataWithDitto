//
//  CustomStore.swift
//  SampleTrips
//
// Taken from https://developer.apple.com/videos/play/wwdc2024/10138/
//

import SwiftData
import Foundation

// Implement a JSON store

@available(swift 5.9) @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
final class JSONStoreConfiguration: DataStoreConfiguration {
    typealias StoreType = JSONStore

    var name: String
    var schema: Schema?
    var fileURL: URL

    init(name: String, schema: Schema? = nil, fileURL: URL) {
        self.name = name
        self.schema = schema
        self.fileURL = fileURL
    }

    static func == (lhs: JSONStoreConfiguration, rhs: JSONStoreConfiguration) -> Bool {
        return lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

@available(swift 5.9) @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
final class JSONStore: DataStore {
    typealias Configuration = JSONStoreConfiguration
    typealias Snapshot = DefaultSnapshot

    var configuration: JSONStoreConfiguration
    var name: String
    var schema: Schema
    var identifier: String

    init(_ configuration: JSONStoreConfiguration, migrationPlan: (any SchemaMigrationPlan.Type)?) throws {
        self.configuration = configuration
        self.name = configuration.name
        self.schema = configuration.schema!
        self.identifier = configuration.fileURL.lastPathComponent
    }

    func save(_ request: DataStoreSaveChangesRequest<DefaultSnapshot>) throws -> DataStoreSaveChangesResult<DefaultSnapshot> {
        var remappedIdentifiers = [PersistentIdentifier: PersistentIdentifier]()
        var serializedTrips = try self.read()

        for snapshot in request.inserted {
            let permanentIdentifier = try PersistentIdentifier.identifier(for: identifier,
                                                                          entityName: snapshot.persistentIdentifier.entityName,
                                                                          primaryKey: UUID())
            let permanentSnapshot = snapshot.copy(persistentIdentifier: permanentIdentifier)
            serializedTrips[permanentIdentifier] = permanentSnapshot
            remappedIdentifiers[snapshot.persistentIdentifier] = permanentIdentifier
        }

        for snapshot in request.updated {
            serializedTrips[snapshot.persistentIdentifier] = snapshot
        }

        for snapshot in request.deleted {
            serializedTrips[snapshot.persistentIdentifier] = nil
        }

        try self.write(serializedTrips)
        return DataStoreSaveChangesResult<DefaultSnapshot>(for: self.identifier,
                                                           remappedPersistentIdentifiers: remappedIdentifiers,
                                                           deletedIdentifiers: request.deleted.map({ $0.persistentIdentifier }))
    }

    func fetch<T>(_ request: DataStoreFetchRequest<T>) throws -> DataStoreFetchResult<T, DefaultSnapshot> where T : PersistentModel {
        if request.descriptor.predicate != nil {
            throw DataStoreError.preferInMemoryFilter
        } else if request.descriptor.sortBy.count > 0 {
            throw DataStoreError.preferInMemorySort
        }

        let objs = try self.read()
        let snapshots = objs.values.map({ $0 })
        return DataStoreFetchResult(descriptor: request.descriptor, fetchedSnapshots: snapshots, relatedSnapshots: objs)
    }

    func read() throws -> [PersistentIdentifier: DefaultSnapshot] {
        if FileManager.default.fileExists(atPath: configuration.fileURL.path(percentEncoded: false)) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let trips = try decoder.decode([DefaultSnapshot].self, from: try Data(contentsOf: configuration.fileURL))
            var result = [PersistentIdentifier: DefaultSnapshot]()
            trips.forEach { s in
                result[s.persistentIdentifier] = s
            }
            return result
        } else {
            return [:]
        }
    }

    func write(_ trips: [PersistentIdentifier: DefaultSnapshot]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(trips.values.map({ $0 }))
        try jsonData.write(to: configuration.fileURL)
    }
}
