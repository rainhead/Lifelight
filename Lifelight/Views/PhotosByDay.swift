//
//  PhotosByDay.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 11/17/24.
//

import SwiftUI
import GRDB

struct PhotosByDay: View {
    @State private var photosByDay: [(Date, [LLPhotoWithObservation].SubSequence)] = []
    @Binding var baseRequest: QueryInterfaceRequest<LLPhotoWithObservation>
    
    var body: some View {
        HStack {
            Text("\(summary.photoCount) photos from \(summary.observationCount) observations of \(summary.taxonCount) taxa.")
                .font(.caption)
                .fontWeight(.light)
        }
        .padding(.all, 10)
        
        ForEach(photosByDay, id: \.0) { (day, photos) in
            Section {
                PhotoGrid(photos: photos)
                    .padding(.bottom, 10)
            } header: {
                HStack {
                    Text(day.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline)
                        .padding(.leading, 10)
                    Spacer()
                }
            }
        }
    }
    
    var summary: Summary {
        Summary(of: photosByDay.flatMap(\.1))
    }

    func reloadPhotos() {
        let request = baseRequest
            .filter(Column("observedOn") != nil)
            .order(Column("observedOn").desc)
        
        Task {
            let photos: [LLPhotoWithObservation] = await LLDatabase.shared.fetchAll(request: request)
            let chunks = LLPhotoWithObservation.chunkByDay(photos: photos)
            photosByDay = chunks
        }
    }
}

fileprivate struct DayChunks {
    let chunks: [(Chunk, [LLPhotoWithObservation].SubSequence)]
    
    static func from(photos: [LLPhotoWithObservation]) -> Self {
        let chunks = photos.chunked(on: { Chunk.from($0.observation) })
        return .init(chunks: chunks)
    }
    
    struct Chunk: Equatable, Identifiable {
        let day: Date
        
        static func from(_ observation: LLObservation) -> Self {
            return .init(day: observation.observedOrCreatedOn)
        }
        
        var heading: String {
            day.formatted(date: .abbreviated, time: .omitted)
        }
        
        var id: Date {
            day
        }
    }
}
