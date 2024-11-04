//
//  LLObservation.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 10/23/24.
//

import Foundation
import GRDB

struct LLObservation: Codable, Identifiable, FetchableRecord, PersistableRecord {
    static let databaseTableName: String = "observations"
    
    let id: Int64
    let createdAt: Date
    let description: String?
    let observedAt: Date?
    let observedOn: Date? // in local timezone
    let updatedAt: Date
    let taxonId: LLTaxon.ID?
    let uri: URL
    
    static func highestId() -> Int? {
        let queue = LLDatabase.shared.queue
        return try! queue.read { db in
            return try Int.fetchOne(db, sql: "SELECT MAX(id) FROM observations")
        }
    }
}

extension LLObservation {
    static let photos = hasMany(LLObservationPhoto.self)
    static let taxon = belongsTo(LLTaxon.self, using: ForeignKey(["taxonId"]))
}

extension LLObservation {
    var observedOrCreatedOn: Date {
        observedOn ?? Calendar.current.startOfDay(for: createdAt)
    }
}
