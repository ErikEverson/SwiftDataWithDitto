//
//  File.swift
//  SampleTrips
//
//  Created by Erik Everson on 6/11/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftData
import Foundation
import DittoSwift
import DictionaryCoder

final class DittoStoreConfiguration: DataStoreConfiguration {
    typealias StoreType = DittoStore

    var name: String
    var schema: Schema?
    var fileURL: URL

    init(name: String, schema: Schema? = nil, fileURL: URL) {
        self.name = name
        self.schema = schema
        self.fileURL = fileURL
    }

    static func == (lhs: DittoStoreConfiguration, rhs: DittoStoreConfiguration) -> Bool {
        return lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

final class DittoStore: DataStore {
    typealias Configuration = DittoStoreConfiguration
    typealias Snapshot = DefaultSnapshot

    var configuration: DittoStoreConfiguration
    var name: String
    var schema: Schema
    var identifier: String

    init(_ configuration: DittoStoreConfiguration, migrationPlan: (any SchemaMigrationPlan.Type)?) throws {
        self.configuration = configuration
        self.name = configuration.name
        self.schema = configuration.schema!
        self.identifier = configuration.fileURL.lastPathComponent
    }

    func save(_ request: DataStoreSaveChangesRequest<Snapshot>) throws -> DataStoreSaveChangesResult<Snapshot> {
        var remappedIdentifiers = [PersistentIdentifier: PersistentIdentifier]()
        var serializedTrips = try self.read()

        for snapshot in request.inserted {
            let permanentIdentifier = try PersistentIdentifier.identifier(for: identifier,
                                                                          entityName: snapshot.persistentIdentifier.entityName,
                                                                          primaryKey: UUID())
            let permanentSnapshot = snapshot.copy(persistentIdentifier: permanentIdentifier)
            serializedTrips[permanentIdentifier] = permanentSnapshot
            remappedIdentifiers[snapshot.persistentIdentifier] = permanentIdentifier
            //try DittoManager.shared.create(snapshot)
        }

        for snapshot in request.updated {
            serializedTrips[snapshot.persistentIdentifier] = snapshot
            //try DittoManager.shared.update(snapshot)
        }

        for snapshot in request.deleted {
            serializedTrips[snapshot.persistentIdentifier] = nil
            //try DittoManager.shared.evict(snapshot)
        }

        try self.write(serializedTrips)
        return DataStoreSaveChangesResult<Snapshot>(for: self.identifier,
                                                           remappedPersistentIdentifiers: remappedIdentifiers,
                                                           deletedIdentifiers: request.deleted.map({ $0.persistentIdentifier }))
    }

    func fetch<T>(_ request: DataStoreFetchRequest<T>) throws -> DataStoreFetchResult<T, Snapshot> where T : PersistentModel {
        if request.descriptor.predicate != nil {
            throw DataStoreError.preferInMemoryFilter
        } else if request.descriptor.sortBy.count > 0 {
            throw DataStoreError.preferInMemorySort
        }

        let objs = try self.read()
        // With the fetch request we would need to support predicates so that someone can get the data that they want with the fetch.
        //let objs = try! DittoManager.shared.read()
        let snapshots = objs.values.map({ $0 })
        return DataStoreFetchResult(descriptor: request.descriptor, fetchedSnapshots: snapshots, relatedSnapshots: objs)
    }

    func read() throws -> [PersistentIdentifier: Snapshot] {
        if FileManager.default.fileExists(atPath: configuration.fileURL.path(percentEncoded: false)) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let trips = try decoder.decode([Snapshot].self, from: try Data(contentsOf: configuration.fileURL))
            var result = [PersistentIdentifier: Snapshot]()
            trips.forEach { s in
                result[s.persistentIdentifier] = s
            }
            return result
        } else {
            return [:]
        }
    }

    func write(_ trips: [PersistentIdentifier: Snapshot]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let trips = trips.values.map({ $0 })
        let jsonData = try encoder.encode(trips)
        print("file being stored here: \(configuration.fileURL.absoluteString)")
        try jsonData.write(to: configuration.fileURL)
    }
}

//final class DittoSnapshot: DataStoreSnapshot {
//    let persistentIdentifier: PersistentIdentifier
//
//    init(from: any BackingData, relatedBackingDatas: inout [PersistentIdentifier : any BackingData]) {
//
//    }
//    
//    func copy(persistentIdentifier: PersistentIdentifier) -> Self {
//
//    }
//
//}
