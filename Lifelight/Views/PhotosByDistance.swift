//
//  PhotosByDistance.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 11/17/24.
//

import SwiftUI
import CoreLocation

fileprivate struct DistanceChunks {
    static let distanceBins: [CLLocationDistance] = [10, 100, 1000, 10_000, 100_000]
    
    let chunks: [(Chunk, [LLPhotoWithObservation].SubSequence)]

    struct Chunk: Equatable, Identifiable {
        let distance: CLLocationDistance
        
        static func from(_ observation: LLObservation, relativeTo origin: CLLocation) -> Self? {
            if let location = observation.location {
                let distance = location.distance(from: origin)
                let bin = distanceBins.last(where: { $0 >= distance }) ?? .nan
                return .init(distance: bin)
            } else {
                return .init(distance: .nan)
            }
        }

        var heading: String {
            if distance.isNaN {
                "Distance unknown"
            } else if distance >= 1000 {
                "Within \(distance / 1000)km"
            } else {
                "Within \(distance)m"
            }
        }
        
        var id: CLLocationDistance {
            distance
        }
    }
}
