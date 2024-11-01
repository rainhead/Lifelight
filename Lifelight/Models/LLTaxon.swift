//
//  LLTaxon.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 10/23/24.
//

import Foundation
import GRDB

struct LLTaxon: Codable, Equatable, Identifiable, FetchableRecord, PersistableRecord {
    static let databaseTableName: String = "taxa"
    
    static func == (lhs: LLTaxon, rhs: LLTaxon) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: Int64
    let isActive: Bool
    let name: String
    let parentId: ID?
    let preferredCommonName: String?
    let rank: String
}

extension LLTaxon {
    static let parent = belongsTo(LLTaxon.self, key: "parentId")
    
    static func matching(substring: String) -> [Self] {
        return try! LLDatabase.shared.queue.read { db in
            return try LLTaxon.filter(sql: "instr(lower(name), ?) > 0", arguments: [substring]).limit(10).fetchAll(db)
        }
    }
}
