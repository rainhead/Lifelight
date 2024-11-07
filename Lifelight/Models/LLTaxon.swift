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
    
    let id: Int
    let isActive: Bool
    let name: String
    let parentId: ID?
    let preferredCommonName: String?
    let rank: String
    
    static func includingDecendants(of taxa: [Self]) -> CommonTableExpression<Void> {
        let ids = taxa.map(\.id)
        let sql = """
SELECT id FROM taxa WHERE id IN (\(ids.map(String.init).joined(separator: ",")))
UNION ALL
SELECT taxa.id FROM taxa JOIN descendants ON taxa.parentId = descendants.id
"""
        return CommonTableExpression(recursive: true, named: "descendants", columns: ["id"], sql: sql)
    }
}

extension LLTaxon {
    static let parent = belongsTo(LLTaxon.self, key: "parentId")
    
    static func matching(substring: String) -> [Self] {
        return try! LLDatabase.shared.queue.read { db in
            return try LLTaxon.filter(sql: "instr(lower(name), ?) > 0", arguments: [substring]).limit(10).fetchAll(db)
        }
    }
}

