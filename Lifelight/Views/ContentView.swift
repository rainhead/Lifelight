//
//  ContentView.swift
//  Natgeist
//
//  Created by Peter Abrahamsen on 10/9/24.
//

import SwiftUI
import Combine
import GRDB
import UniformTypeIdentifiers
import CoreLocation

enum SearchRefinement: Equatable, Identifiable {
    case month(Month)
    case taxon(LLTaxon)
    
    var id: String {
        switch self {
        case .month(let month): month.asString // what could go wrong
        case .taxon(let taxon): String(taxon.id)
        }
    }

    var token: Text {
        switch self {
        case .month(let month): Text(month.asString)
        case .taxon(let taxon): Text(taxon.name)
        }
    }
}

extension [SearchRefinement] {
    var months: [Month] {
        compactMap { if case let .month(month) = $0 { month } else { nil } }
    }
    
    var taxa: [LLTaxon] {
        compactMap { if case let .taxon(taxon) = $0 { taxon } else { nil } }
    }
}

struct Summary: FetchableRecord, Decodable {
    let photoCount: Int
    let observationCount: Int
    let taxonCount: Int
    
    init(of photos: [LLPhotoWithObservation]) {
        photoCount = photos.count
        observationCount = Set(photos.map(\.observation.id)).count
        taxonCount = Set(photos.map(\.observation.taxonId)).count
    }
}

struct ContentView: View {
    @State var photosByDay: [(Date, [LLPhotoWithObservation].SubSequence)] = []
    
    @State fileprivate var query = ObservationQuery()
    @State fileprivate var searchString = ""
    @State fileprivate var suggestedTaxa = [LLTaxon]()
    @State fileprivate var suggestedMonths = [Month]()
    @State fileprivate var summary = Summary(of: [])
    @State fileprivate var exportDialogIsPresented = false
    @State var currentLocation: CLLocation? = CLLocation(latitude: 47.6205, longitude: 122.351)

    var body: some View {
        NavigationStack {
            ScrollView {
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
            .navigationTitle("My Observations")
            #if os(macOS)
            .toolbar {
                ToolbarItemGroup {
                    Button("Export") {
                        exportDialogIsPresented = true
                    }
                }
            }
            #endif
            .fileExporter(isPresented: $exportDialogIsPresented, document: document, contentType: UTType.commaSeparatedText, defaultFilename: "my_observations.csv") { result in
                if case let .failure(error) = result {
                    debugPrint(error)
                }
            }
            .refreshable {
                debugPrint("Refresh!")
            }
            .onChange(of: query.refinements, initial: true) {
                debugPrint("Reloading observations due to query change")
                reloadPhotos()
            }
            .onReceive(NotificationCenter.default.publisher(for: .databaseDidChange).debounce(for: .seconds(1), scheduler: RunLoop.main), perform: { _ in
                debugPrint("Reloading observations due to database change")
                reloadPhotos()
            })
            .onChange(of: searchString) { _, string in
                let preparedSearchString = searchString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if preparedSearchString.isEmpty {
                    suggestedTaxa = []
                    suggestedMonths = []
                } else {
                    suggestedMonths = Month.allCases.filter { $0.asString.lowercased().hasPrefix(preparedSearchString) }
                    debugPrint("Fetching taxa matching '\(preparedSearchString)'")
                    suggestedTaxa = LLTaxon.matching(substring: preparedSearchString)
                }
            }
            .searchable(text: $searchString, tokens: $query.refinements) { refinement in
                refinement.token
            }
            .searchSuggestions {
                if !suggestedMonths.isEmpty {
                    Text("In month").font(.caption).opacity(0.7).bold()
                    ForEach(suggestedMonths) { month in
                        Label(month.asString, systemImage: "calendar").searchCompletion(SearchRefinement.month(month))
                    }
                }
                
                if !suggestedTaxa.isEmpty {
                    Text("Of taxon").font(.caption).opacity(0.7).bold()
                    ForEach(suggestedTaxa) { taxon in
                        Label(taxon.name, systemImage: "list.bullet.indent").searchCompletion(SearchRefinement.taxon(taxon))
                    }
                }
            }
        }
    }
    
    // Any of these taxa (if any) AND any of these months (if any)
    var dbRequest: QueryInterfaceRequest<LLObservationPhoto> {
        var observations = LLObservationPhoto.observation
        if !query.refinements.taxa.isEmpty {
            let cte = LLTaxon.includingDecendants(of: query.refinements.taxa)
            observations = observations.with(cte).filter(cte.all().contains(Column("taxonId")))
        }
        if !query.refinements.months.isEmpty {
            observations = observations.filter(LLObservation.duringMonths(query.refinements.months))
        }
        return LLObservationPhoto.including(required: observations).order(sql: "coalesce(observedOn, observations.createdAt) DESC")
    }
    
    var document: LLObservationFile {
        var observations = LLObservation.including(required: LLObservation.taxon)
        if !query.refinements.taxa.isEmpty {
            let cte = LLTaxon.includingDecendants(of: query.refinements.taxa)
            observations = observations.with(cte).filter(cte.all().contains(Column("taxonId")))
        }
        if !query.refinements.months.isEmpty {
            observations = observations.filter(LLObservation.duringMonths(query.refinements.months))
        }
        return LLObservationFile(request: observations)
    }

    func reloadPhotos() {
        let request = dbRequest
        Task {
            let photos: [LLPhotoWithObservation] = await LLDatabase.shared.fetchAll(request: request)
            self.summary = Summary(of: photos)
            let chunks = LLPhotoWithObservation.chunkByDay(photos: photos)
            photosByDay = chunks
        }
    }
}

#Preview {
    ContentView()
}
