//
//  LLObservation.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 10/23/24.
//

import Foundation
import GRDB

struct LLObservation: Codable, Identifiable, FetchableRecord, PersistableRecord {
    let id: Int64
    let createdAt: Date
    let description: String?
    let observedAt: Date?
    let observedOn: Date? // in local timezone
    let updatedAt: Date
    let taxonID: LLTaxon.ID?
}
