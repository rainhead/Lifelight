//
//  LLObservationPhoto.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 10/23/24.
//

import Foundation
import GRDB

struct LLObservationPhoto: Codable, Identifiable, FetchableRecord, PersistableRecord {
    static let databaseTableName: String = "observationPhotos"
    
    let id: Int64
    let observationId: Int64
    let position: Int
    let originalHeight: UInt
    let originalWidth: UInt
    let squareURL: URL
    
    var observation: QueryInterfaceRequest<LLObservation> {
        request(for: LLObservationPhoto.observation)
    }
}

extension LLObservationPhoto {
    static let observation = belongsTo(LLObservation.self, using: ForeignKey(["observationId"]))
}

extension LLObservationPhoto {
    var largeURL: URL { URL(string: "large.\(squareURL.pathExtension)", relativeTo: squareURL)! } // max dimension 1024px
    var mediumURL: URL { URL(string: "medium.\(squareURL.pathExtension)", relativeTo: squareURL)! } // max dimension 500px
    var originalURL: URL { URL(string: "original.\(squareURL.pathExtension)", relativeTo: squareURL)! } // max dimension 2048px
    var smallURL: URL { URL(string: "small.\(squareURL.pathExtension)", relativeTo: squareURL)! } // max dimension 240px
    var thumbURL: URL { URL(string: "thumb.\(squareURL.pathExtension)", relativeTo: squareURL)! } // max dimension 100px
}

struct LLPhotoWithObservation: Identifiable, FetchableRecord, Decodable {
    let observation: LLObservation
    let photo: LLObservationPhoto
    
    var id: LLObservationPhoto.ID { photo.id }
}
