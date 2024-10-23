//
//  ContentView.swift
//  Natgeist
//
//  Created by Peter Abrahamsen on 10/9/24.
//

import SwiftUI

struct ContentView: View {
    @Binding var observations: [(Date, [INaturalistObservation].SubSequence)]
    
    let imageWidth: Double = 80
    let imageSpacing: Double = 5.0
    
    var body: some View {
        List(observations, id: \.0) { (day, observations) in
            Section(day.formatted(date: .abbreviated, time: .omitted)) {
                PhotoGrid(observations: observations)
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

//#Preview {
//    @Previewable @State var observations = {
//        let fixtureURL = Bundle.main.url(forResource: "my_observations", withExtension: "json")!
//        let page: PagedResponse<INaturalistObservation> = loadFixtureFrom(fixtureURL)
//        return page.results.sorted().chunked(on: \.observedOrCreatedOn)
//    }()
//    ContentView(observations: $observations)
//}
