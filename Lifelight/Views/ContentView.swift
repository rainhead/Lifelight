//
//  ContentView.swift
//  Natgeist
//
//  Created by Peter Abrahamsen on 10/9/24.
//

import SwiftUI
import Combine
import GRDB

struct ContentView: View {
    @State var photosByDay: [(Date, [LLPhotoWithObservation].SubSequence)] = []
    
    @State var searchString = ""
    @State var selectedTaxa = [LLTaxon]()
    @State var suggestedTaxa = [LLTaxon]()

    var body: some View {
        NavigationStack {
            VStack {
                List(photosByDay, id: \.0) { (day, photos) in
                    Section(day.formatted(date: .abbreviated, time: .omitted)) {
                        PhotoGrid(photos: photos)
                            .listRowInsets(.none)
                    }
                    .listSectionSeparator(.hidden)
                    .listRowSeparator(.hidden)
                }
#if os(macOS)
                .listStyle(.plain)
#else
                .listStyle(.grouped)
#endif
            }
            .onChange(of: preparedSearchString, initial: true) {
                debugPrint("Reloading observations due to query change")
                reloadPhotos()
            }
            .onChange(of: selectedTaxa, initial: true) {
                debugPrint("Reloading observations due to query change")
                reloadPhotos()
            }
            .onReceive(NotificationCenter.default.publisher(for: .databaseDidChange).debounce(for: .seconds(1), scheduler: RunLoop.main), perform: { _ in
                debugPrint("Reloading observations due to database change")
                reloadPhotos()
            })
            .onChange(of: preparedSearchString) { _, string in
                if string.isEmpty { suggestedTaxa = [] }
                // NB: suggested tokens are displayed only when the search string is empty, so it is not very useful
                
                debugPrint("Fetching taxa matching '\(string)'")
                suggestedTaxa = LLTaxon.matching(substring: string)
            }
            .searchable(text: $searchString, tokens: $selectedTaxa) { taxon in
                Text(taxon.name)
            }
            .searchSuggestions {
                ForEach(suggestedTaxa) { taxon in
                    Text(taxon.name).searchCompletion(taxon)
                }
            }
        }
    }
    
    var preparedSearchString: String {
        return searchString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    var dbRequest: QueryInterfaceRequest<LLObservationPhoto> {
        var request: QueryInterfaceRequest<LLObservationPhoto>
        let searchString = preparedSearchString
        if !searchString.isEmpty {
            request = LLObservationPhoto.including(required: LLObservationPhoto.observation.including(required: LLObservation.taxon.filter(Column("name").lowercased == searchString)))
        } else if !selectedTaxa.isEmpty {
            request = LLObservationPhoto.including(required: LLObservationPhoto.observation.filter(selectedTaxa.map(\.id).contains(Column("taxonId"))))
        } else {
            request = LLObservationPhoto.including(required: LLObservationPhoto.observation)
        }
        request = request.order(sql: "coalesce(observedOn, observations.createdAt) DESC")
        return request
    }
    
    func reloadPhotos() {
        let request = dbRequest
        Task {
            let photos: [LLPhotoWithObservation] = await LLDatabase.shared.fetchAll(request: request)
            let chunks = LLPhotoWithObservation.chunkByDay(photos: photos)
            photosByDay = chunks
        }
    }
}

#Preview {
    ContentView()
}
