//
//  LLObservation.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 10/23/24.
//

import Foundation
import GRDB
import CoreLocation

struct LLObservation: Codable, Identifiable, FetchableRecord, PersistableRecord {
    static let databaseTableName: String = "observations"
    
    let id: Int64
    let createdAt: Date
    let description: String?
    let latitude: Double?
    let longitude: Double?
    let locationObscured: Bool
    let observedAt: Date?
    let observedOn: Date? // in local timezone
    let updatedAt: Date
    let taxonId: LLTaxon.ID?
    let uri: URL
    
    var taxon: QueryInterfaceRequest<LLTaxon> {
        request(for: LLObservation.taxon)
    }
    
    var location: CLLocation? {
        guard let longitude, let latitude else { return nil }
        return CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), altitude: 0, horizontalAccuracy: kCLLocationAccuracyBest, verticalAccuracy: kCLLocationAccuracyBest, timestamp: observedAt ?? createdAt)
    }
    
    static func highestId() -> ID? {
        let queue = LLDatabase.shared.queue
        return try! queue.read { db in
            return try ID.fetchOne(db, sql: "SELECT MAX(id) FROM observations")
        }
    }
    
    static func duringMonths(_ months: [Month]) -> SQLExpression {
        months.contains(SQL("cast(strftime('%m', coalesce(observations.observedOn, observations.createdAt)) as integer)"))
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

extension OrderedRequest {
    func orderByDistance(from origin: CLLocation) -> Self {
        order(
            sql: "sqrt(pow(latitude - :latitude, 2) + pow(longitude - :longitude, 2)) DESC, observations.id DESC",
            arguments: ["latitude": origin.coordinate.latitude, "longitude": origin.coordinate.longitude]
        )
    }
}

extension FilteredRequest {
    func within(km: Double, of point: CLLocationCoordinate2D) -> Self {
        let longitudinalOffset = 40075.0 * cos(point.latitude) / 360.0
        let latitudinalOffset = km / 111.32
        let lonMin = (point.longitude - longitudinalOffset).remainder(dividingBy: 180.0)
        let lonMax = (point.longitude + longitudinalOffset).remainder(dividingBy: 180.0)
        let latMin = (point.latitude - latitudinalOffset).remainder(dividingBy: 180.0)
        let latMax = (point.latitude + latitudinalOffset).remainder(dividingBy: 180.0)
        return filter(
            sql: "longitude BETWEEN :lonMin AND :lonMax AND latitude BETWEEN :latMin AND :latMax",
            arguments: ["lonMin": lonMin, "lonMax": lonMax, "latMin": latMin, "latMax": latMax]
        )
    }
}

struct LLObservationWithTaxon: Identifiable, FetchableRecord, Decodable {
    let observation: LLObservation
    let taxon: LLTaxon?
    
    var id: LLObservation.ID { observation.id }
}
