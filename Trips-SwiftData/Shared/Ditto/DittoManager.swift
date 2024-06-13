//
//  DittoManager.swift
//  SampleTrips
//
//  Created by Erik Everson on 6/13/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftData
import DittoSwift
import DictionaryCoder

// I guess we need this to make the singleton pattern be accepted for Ditto and Swift 6.
extension Ditto: @unchecked @retroactive Sendable {}
extension DittoQueryResult: @unchecked @retroactive Sendable {}

// Cant use an actor here unless we want to move all the async stuff to the Ditto Store
final class DittoManager: Sendable {
    static let shared = DittoManager()
    let dittoDir: URL
    let ditto: Ditto

    init() {
        dittoDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("Ditto")
        ditto = Ditto(identity: .onlinePlayground(appID: "Your app id here", token: "your token here"), persistenceDirectory: dittoDir)
        try! ditto.sync.registerSubscription(query: "SELECT * FROM trips LIMIT 1000")
        try! ditto.startSync()
    }

    func create(_ snapshot: DefaultSnapshot) throws {
        Task {
            let encoder = DictionaryEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.nilEncodingStrategy = .useNSNull
            let newDocument = try encoder.encode(snapshot)
            guard let collectionName = newDocument["collectionName"] as? String else { throw NSError() }

            let result = try await self.ditto.store.execute(query: "INSERT INTO \(collectionName) DOCUMENTS (:new)", arguments: ["new": newDocument])
            print(result)
        }
    }

    func update(_ snapshot: DefaultSnapshot) throws {
        Task {
            let encoder = DictionaryEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.nilEncodingStrategy = .useNSNull
            let newDocument = try encoder.encode(snapshot)
            guard let collectionName = newDocument["collectionName"] as? String else { throw NSError() }

            //guard let docID = newDocument["_id"] as? String else { throw NSError() }
//            let result = try await self.ditto.store.execute(query: "UPDATE trips SET destination = 'Denver' WHERE _id = :id ", arguments: ["id": docID])

            let result = try await self.ditto.store.execute(query: "INSERT INTO \(collectionName) DOCUMENTS (:new) ON ID CONFLICT DO UPDATE", arguments: ["new": newDocument])
            print(result)
        }
    }

    func evict(_ snapshot: DefaultSnapshot) throws {
        Task {
            let encoder = DictionaryEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.nilEncodingStrategy = .useNSNull
            let newDocument = try encoder.encode(snapshot)
            guard let collectionName = newDocument["collectionName"] as? String else { throw NSError() }
            guard let docID = newDocument["_id"] as? String else { throw NSError() }

            let result = try await self.ditto.store.execute(query: "EVICT FROM \(collectionName) WHERE _id = :id", arguments: ["id": docID])
            print(result)
        }
    }

    // This way of doing things is said to not be safe and can cause issues
    // Using this for now to get it working but would need to validate that
    // we can do this or something like it safely
    func read() throws -> [PersistentIdentifier: DittoStore.Snapshot] {
        var result = [PersistentIdentifier: DittoStore.Snapshot]()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        class Enclosure: @unchecked Sendable {
            var value: DittoQueryResult?
        }

        let semaphore = DispatchSemaphore(value: 0)
        let semaphore2 = DispatchSemaphore(value: 0)
        let semaphore3 = DispatchSemaphore(value: 0)
        let enclosure = Enclosure()

        Task {
            enclosure.value = try await self.ditto.store.execute(query: "SELECT * FROM trips LIMIT 1000")
            semaphore.signal()
        }
        semaphore.wait()

        guard let queryResult = enclosure.value else { throw NSError() }

        let trips = try queryResult.items.map { dittoQueryResultItem in
            try decoder.decode(DittoStore.Snapshot.self, from: dittoQueryResultItem.jsonData())
        }

        trips.forEach { s in
            result[s.persistentIdentifier] = s
        }

        enclosure.value = nil

        Task {
            enclosure.value = try await self.ditto.store.execute(query: "SELECT * FROM livingAccommodation LIMIT 1000")
            semaphore2.signal()
        }
        semaphore2.wait()

        guard let queryResult = enclosure.value else { throw NSError() }

        let livingAccommodation = try queryResult.items.map { dittoQueryResultItem in
            try decoder.decode(DittoStore.Snapshot.self, from: dittoQueryResultItem.jsonData())
        }

        livingAccommodation.forEach { s in
            result[s.persistentIdentifier] = s
        }

        enclosure.value = nil

        Task {
            enclosure.value = try await self.ditto.store.execute(query: "SELECT * FROM bucketList LIMIT 1000")
            semaphore3.signal()
        }
        semaphore3.wait()

        guard let queryResult = enclosure.value else { throw NSError() }

        let bucketList = try queryResult.items.map { dittoQueryResultItem in
            try decoder.decode(DittoStore.Snapshot.self, from: dittoQueryResultItem.jsonData())
        }

        bucketList.forEach { s in
            result[s.persistentIdentifier] = s
        }

        return result
    }
}
