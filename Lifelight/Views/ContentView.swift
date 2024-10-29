//
//  ContentView.swift
//  Natgeist
//
//  Created by Peter Abrahamsen on 10/9/24.
//

import SwiftUI

let species = [
    "Bombus caliginosus",
    "Bombus fervidus",
    "Bombus mixtus",
    "Bombus nevadensis",
    "Bombus vosnesenskii",
    "Coelioxys rufitarsis",
    "Halictus rubicundus"
]

struct ContentView: View {
    @Binding var photosByDay: [(Date, [LLPhotoWithObservation].SubSequence)]
    @State var taxonFilter: String = ""
    
    var body: some View {
        let taxonSearch = taxonFilter.lowercased()
        let suggestions = species.filter { $0.lowercased().starts(with: taxonSearch) }
        VStack {
            TextField("Taxon", text: $taxonFilter)
                .textInputSuggestions(suggestions, id: \.self) { species in
                    Text(species).textInputCompletion(species)
                }
//            HStack {
//                Spacer()
//                DatePicker("Since", selection: $sinceDate, displayedComponents: [.date])
//                DatePicker("Until", selection: $untilDate, displayedComponents: [.date])
//            }
//            .padding(.horizontal)
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
    }
}

#Preview {
    @Previewable @State var observations = {
        let myObs = MyObservations(userName: "rainhead")
        myObs.loadFixture(named: "my_observations")
        return myObs.photosByDay()
    }()
    ContentView(photosByDay: .constant(observations))
}
