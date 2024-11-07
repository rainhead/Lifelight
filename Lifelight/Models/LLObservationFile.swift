//
//  LLObservationFile.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 11/7/24.
//

import SwiftUI
import UniformTypeIdentifiers
import GRDB

struct LLObservationFile: FileDocument {
    static let readableContentTypes = [UTType.commaSeparatedText]
    
    static let dateFormatter = {
        var formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MM-dd-yyyy"
        return formatter
    }()
    
    let request: QueryInterfaceRequest<LLObservation>
    
    init(request: QueryInterfaceRequest<LLObservation>) {
        self.request = request
    }

    init(configuration: ReadConfiguration) throws {
        fatalError("We don't read files.")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let request = self.request
            .including(optional: LLObservation.taxon)
            .order(Column("id").asc)
        let observations = try LLDatabase.shared.queue.read { db in
            db.trace { debugPrint($0) }
            return try LLObservationWithTaxon.fetchAll(db, request)
        }
        var lines = ["id,observedOn,createdAt,taxonName"]
        lines.append(contentsOf: observations.map { obs in
            [
                String(obs.id),
                obs.observation.observedOn != nil ? LLObservationFile.dateFormatter.string(from: obs.observation.observedOn!) : "",
                obs.observation.createdAt.formatted(.iso8601),
                obs.taxon?.name ?? ""
                
            ].joined(separator: ",")
        })
        return FileWrapper(regularFileWithContents: lines.joined(separator: "\n").data(using: .utf8)!)
    }
}
