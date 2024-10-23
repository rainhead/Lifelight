//
//  LLTaxon.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 10/23/24.
//

import Foundation
import GRDB

struct LLTaxon: Codable, Identifiable, FetchableRecord, PersistableRecord {
    let id: Int64
    let isActive: Bool
    let name: String
    let parentId: Int64?
    let preferredCommonName: String?
    let rank: String
}
