//
//  ContentView.swift
//  Natgeist
//
//  Created by Peter Abrahamsen on 10/9/24.
//

import SwiftUI

struct ContentView: View {
    @Binding var photosByDay: [(Date, [LLPhotoWithObservation].SubSequence)]
    @Binding var calendarFilter: DateComponents
    
    let imageWidth: Double = 80
    let imageSpacing: Double = 5.0
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(String(calendarFilter.year ?? 2000)).opacity(calendarFilter.year == nil ? 0 : 1)
                Menu {
                    Picker(selection: $calendarFilter.year, label: Text("Year")) {
                        Text("All").tag(nil as Int?)
                        Text("2024").tag(2024)
                        Text("2023").tag(2023)
                    }
                } label: {
                    Image(systemName: "calendar")
                }
            }
            .padding(.horizontal)
            List(photosByDay, id: \.0) { (day, photos) in
                Section(day.formatted(date: .abbreviated, time: .omitted)) {
                    PhotoGrid(photos: photos)
                }
                .listSectionSeparator(.hidden)
                .listRowInsets(.none)
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

//#Preview {
//    @Previewable @State var observations = {
//        let fixtureURL = Bundle.main.url(forResource: "my_observations", withExtension: "json")!
//        let page: PagedResponse<INaturalistObservation> = loadFixtureFrom(fixtureURL)
//        return page.results.sorted().chunked(on: \.observedOrCreatedOn)
//    }()
//    ContentView(observations: $observations)
//}
