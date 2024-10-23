//
//  LLObservationPhoto.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 10/23/24.
//

import Foundation
import GRDB

struct LLObservationPhoto: Identifiable, Codable, FetchableRecord, PersistableRecord {
    let id: Int64
    let observationID: LLObservation.ID
    let position: Int
    let originalHeight: UInt
    let originalWidth: UInt
    let squareURL: URL
}
