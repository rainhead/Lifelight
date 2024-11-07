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
    
    @State var searchRefinements = [SearchRefinement]()
    @State var searchString = ""
    @State var selectedRefinements = [SearchRefinement]()
    @State var suggestedTaxa = [LLTaxon]()
    @State var suggestedMonths = [Month]()
    @State var summary = Summary(of: [])
    @State var exportDialogIsPresented = false

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
            .toolbar {
                ToolbarItemGroup {
                    Button("Export") {
                        exportDialogIsPresented = true
                    }
                }
            }
            .fileExporter(isPresented: $exportDialogIsPresented, document: document, contentType: UTType.commaSeparatedText, defaultFilename: "my_observations.csv") { result in
                if case let .failure(error) = result {
                    debugPrint(error)
                }
            }
            .refreshable {
                debugPrint("Refresh!")
            }
            .onChange(of: selectedRefinements, initial: true) {
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
            .searchable(text: $searchString, tokens: $selectedRefinements) { refinement in
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
    
    var selectedTaxa: [LLTaxon] {
        selectedRefinements.compactMap { if case let .taxon(taxon) = $0 { taxon } else { nil } }
    }
    
    var selectedMonths: [Month] {
        selectedRefinements.compactMap { if case let .month(month) = $0 { month } else { nil } }
    }
    
    // Any of these taxa (if any) AND any of these months (if any)
    var dbRequest: QueryInterfaceRequest<LLObservationPhoto> {
        var observations = LLObservationPhoto.observation
        if !selectedTaxa.isEmpty {
            let cte = LLTaxon.includingDecendants(of: selectedTaxa)
            observations = observations.with(cte).filter(cte.all().contains(Column("taxonId")))
        }
        if !selectedMonths.isEmpty {
            observations = observations.filter(LLObservation.duringMonths(selectedMonths))
        }
        return LLObservationPhoto.including(required: observations).order(sql: "coalesce(observedOn, observations.createdAt) DESC")
    }
    
    var document: LLObservationFile {
        var observations = LLObservation.including(required: LLObservation.taxon)
        if !selectedTaxa.isEmpty {
            let cte = LLTaxon.includingDecendants(of: selectedTaxa)
            observations = observations.with(cte).filter(cte.all().contains(Column("taxonId")))
        }
        if !selectedMonths.isEmpty {
            observations = observations.filter(LLObservation.duringMonths(selectedMonths))
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
