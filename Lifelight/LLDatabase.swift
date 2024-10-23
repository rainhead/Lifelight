//
//  Database.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 10/22/24.
//

import Foundation
import GRDB

final class LLDatabase {
    private let queue: DatabaseQueue
    
    init() {
        do {
            self.queue = try DatabaseQueue()
            try queue.write { db in
                try db.create(table: "llTaxon") { t in
                    t.primaryKey("id", .integer)
                    t.column("isActive", .boolean).notNull()
                    t.column("name", .text).notNull()
                    t.column("parentID", .integer)
                    t.column("preferredCommonName", .text)
                    t.column("rank", .text).notNull()
                }
                try db.create(table: "llObservation") { t in
                    t.primaryKey("id", .integer)
                    t.column("createdAt", .datetime).notNull()
                    t.column("description", .text)
                    t.column("observedAt", .datetime)
                    t.column("observedOn", .date)
                    t.column("updatedAt", .datetime).notNull()
                    t.column("taxonID", .integer)
                }
                try db.create(table: "llObservationPhoto") { t in
                    t.primaryKey("id", .integer)
                    t.column("observationID", .integer).notNull().indexed()
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
    
    func addObservations(_ observations: [LLObservation]) {
        do {
            try queue.write { db in
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
            try queue.write { db in
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
            try queue.write { db in
                for taxon in taxa {
                    try taxon.upsert(db)
                }
            }
        } catch {
            debugPrint("Error adding taxon: \(error)")
        }
    }
}
