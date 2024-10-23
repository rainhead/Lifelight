//
//  Database.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 10/22/24.
//

import DuckDB
import Foundation
import TabularData

final class LLDatabase {
    private let db: Database
    private let conn: Connection
    private static let schema = try! String(data: Data(contentsOf: Bundle.main.url(forResource: "schema", withExtension: "sql")!), encoding: .utf8)!
    
    init() {
        self.db = try! Database(store: .inMemory)
        self.conn = try! db.connect()
        try! conn.execute(LLDatabase.schema)
    }
    
    func appendObservations(observations: [INaturalistObservation]) {
        do {
            appendTaxa(taxa: observations.compactMap(\.taxon))
            
            let beforeCount = try conn.query("SELECT COUNT(*) FROM observations")[0].cast(to: Int.self)[0]!
            try conn.execute("CREATE OR REPLACE TEMP TABLE new_observations AS SELECT * FROM observations LIMIT 0")
            let appender = try! Appender(connection: conn, table: "observations")
            for obs in observations {
                try appender.append(obs.id)
                try appender.append(obs.created_at.formatted(.iso8601))
                try appender.append(obs.description)
                try appender.append(obs.taxon?.id)
                try appender.append(obs.time_observed_at?.formatted(.iso8601))
                try appender.append(obs.uri.absoluteString)
                try appender.append(obs.uuid.uuidString)
                try appender.endRow()
            }
            try appender.flush()
            try conn.execute("INSERT INTO observations SELECT * FROM new_observations ON CONFLICT DO UPDATE SET description = EXCLUDED.description, taxon_id = EXCLUDED.taxon_id, time_observed_at = EXCLUDED.time_observed_at")
            try conn.execute("DROP TEMP TABLE new_observations")
            let afterCount = try conn.query("SELECT COUNT(*) FROM observations")[0].cast(to: Int.self)[0]!
            debugPrint("Inserted \(afterCount - beforeCount) new observations.")
        } catch {
            debugPrint("Failed to insert new observations: \(error)")
        }
    }
    
    func appendTaxa(taxa: [INaturalistTaxon]) {
        do {
            let beforeCount = try conn.query("SELECT COUNT(*) FROM taxa")[0].cast(to: Int.self)[0]!
            debugPrint("Found \(beforeCount) preexisting taxa")
            try conn.execute("CREATE OR REPLACE TEMP TABLE new_taxa AS SELECT * FROM taxa LIMIT 0")
            let appender = try! Appender(connection: conn, table: "new_taxa")
            for taxon in taxa {
                try appender.append(taxon.id)
                try appender.append(taxon.is_active)
                try appender.append(taxon.name)
                try appender.append(taxon.parent_id)
                try appender.append(taxon.preferred_common_name)
                try appender.append(taxon.rank.rawValue)
                try appender.endRow()
            }
            try appender.flush()
            try conn.execute("INSERT INTO taxa SELECT DISTINCT ON (id) * FROM new_taxa ON CONFLICT DO UPDATE SET is_active = EXCLUDED.is_active, preferred_common_name = EXCLUDED.preferred_common_name")
            try conn.execute("DROP TEMP TABLE new_taxa")
            let afterCount = try conn.query("SELECT COUNT(*) FROM taxa")[0].cast(to: Int.self)[0]!
            debugPrint("Inserted \(afterCount - beforeCount) new taxa.")
        } catch {
            debugPrint("Failed to insert new taxa: \(error)")
        }
    }
}
