//
//  ContentView.swift
//  Natgeist
//
//  Created by Peter Abrahamsen on 10/9/24.
//

import SwiftUI
import Combine
import GRDB

enum Month: Int, Equatable, Identifiable, CaseIterable {
    case january = 1
    case february = 2
    case march = 3
    case april = 4
    case may = 5
    case june = 6
    case july = 7
    case august = 8
    case september = 9
    case october = 10
    case november = 11
    case december = 12
    
    var id: Self { self }
    
    var asString: String {
        switch self {
        case .january: "January"
        case .february: "February"
        case .march: "March"
        case .april: "April"
        case .may: "May"
        case .june: "June"
        case .july: "July"
        case .august: "August"
        case .september: "September"
        case .october: "October"
        case .november: "November"
        case .december: "December"
        }
    }
}

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
    
    // Any of these taxa (if any) AND any of these months (if any)
    var dbRequest: QueryInterfaceRequest<LLObservationPhoto> {
        var observation = LLObservationPhoto.observation
        let selectedTaxa = selectedRefinements.compactMap { if case let .taxon(taxon) = $0 { taxon.id } else { nil } }
        if !selectedTaxa.isEmpty {
            let cte = LLTaxon.descendants(of: selectedTaxa)
            observation = observation.with(cte).filter(cte.all().contains(Column("taxonId")))
        }
        let selectedMonths = selectedRefinements.compactMap { if case let .month(month) = $0 { month.rawValue } else { nil } }
        if !selectedMonths.isEmpty {
            observation = observation.filter(selectedMonths.contains(SQL("cast(strftime('%m', coalesce(observations.observedOn, observations.createdAt)) as integer)")))
        }
        return LLObservationPhoto.including(required: observation).order(sql: "coalesce(observedOn, observations.createdAt) DESC")
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
