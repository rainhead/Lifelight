//
//  Database.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 10/22/24.
//

import Foundation
import GRDB
import Combine

struct LLDatabase {
    static let shared = Self()
    
    let queue: DatabaseQueue

    init() {
        do {
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("lifelight.sqlite")
            debugPrint("Initializing database at \(path.absoluteString)")
            Inflections.default.irregularSuffix("taxon", "taxa")
            self.queue = try DatabaseQueue(path: path.absoluteString)
            try queue.write { db in
                try db.create(table: "taxa", ifNotExists: true) { t in
                    t.primaryKey("id", .integer)
                    t.column("isActive", .boolean).notNull()
                    t.column("name", .text).notNull().indexed()
                    t.column("parentId", .integer)
                    t.column("preferredCommonName", .text)
                    t.column("rank", .text).notNull()
                }
                try db.create(table: "observations", ifNotExists: true) { t in
                    t.primaryKey("id", .integer)
                    t.column("createdAt", .datetime).notNull()
                    t.column("description", .text)
                    t.column("latitude", .double).indexed()
                    t.column("longitude", .double).indexed()
                    t.column("locationObscured", .boolean)
                    t.column("observedAt", .datetime)
                    t.column("observedOn", .date)
                    t.column("updatedAt", .datetime).notNull()
                    t.column("taxonID", .integer)
                    t.column("uri", .text).notNull()
                }
                try db.create(table: "observationPhotos", ifNotExists: true) { t in
                    t.primaryKey("id", .integer)
                    t.column("observationId", .integer).notNull().indexed()
                    t.column("position", .integer).notNull()
                    t.column("originalHeight", .integer).notNull()
                    t.column("originalWidth", .integer).notNull()
                    t.column("squareURL", .text).notNull()
                }
            }
        } catch {
            fatalError("Error initializing database: \(error)")
        }
    }
    
    static func withFixture(named: String) -> Self {
        let fixtureURL = Bundle.main.url(forResource: "my_observations", withExtension: "json")!
        let page: PagedResponse<INaturalistObservation> = loadFixtureFrom(fixtureURL)
        let db = Self()
        db.receiveObservations(page.results)
        return db
    }
        
    nonisolated func receiveObservations(_ observations: [INaturalistObservation]) {
        guard !observations.isEmpty else { return }
        
        addTaxa(observations.compactMap(\.taxon).map(\.llTaxon))
        addObservations(observations.map(\.llObservation))
        addObservationPhotos(observations.flatMap(\.llObservationPhotos))
        NotificationCenter.default.post(name: .databaseDidChange, object: Date())
    }
    
    func loadObservationFixture(named: String) {
    }

    func addObservations(_ observations: [LLObservation]) {
        do {
            try queue.writeWithoutTransaction { db in
                for obs in observations {
                    try obs.upsert(db)
                }
            }
        } catch {
            debugPrint("Error adding observation: \(error)")
        }
    }
    
    func addObservationPhotos(_ photos: [LLObservationPhoto]) {
        do {
            try queue.writeWithoutTransaction { db in
                for photo in photos {
                    try photo.upsert(db)
                }
            }
        } catch {
            debugPrint("Error adding observation photo: \(error)")
        }
    }
    
    func addTaxa(_ taxa: [LLTaxon]) {
        do {
            try queue.writeWithoutTransaction { db in
                for taxon in taxa {
                    try taxon.upsert(db)
                }
            }
        } catch {
            debugPrint("Error adding taxon: \(error)")
        }
    }
    
    
    nonisolated func fetchAll<T: FetchableRecord & Sendable>(request: some FetchRequest) async -> [T] {
        let startTime = CFAbsoluteTimeGetCurrent()
        let records = try! await LLDatabase.shared.queue.read { db in
            db.trace(options: .statement) { debugPrint($0) }
            let records = try T.fetchAll(db, request)
            db.trace(options: .statement, nil)
            return records
        }
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        debugPrint("Done selecting data. Elapsed time: \(timeElapsed) seconds.")
        return records
    }
}

extension NSNotification.Name {
    static let databaseDidChange = NSNotification.Name("databaseDidChange")
}
