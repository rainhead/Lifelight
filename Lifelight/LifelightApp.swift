//
//  LifelightApp.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 10/17/24.
//

import SwiftUI

@main
struct LifelightApp: App {
    @State var photosByDay = [(Date, [LLPhotoWithObservation].SubSequence)]()
    @State var calendarFilter = DateComponents(year: nil, month: 0, day: 0, hour: 0, minute: 0, second: 0)
    @State var myObservations = MyINaturalistObservations(userName: "rainhead")

    var body: some Scene {
        WindowGroup {
            ContentView(photosByDay: $photosByDay, calendarFilter: $calendarFilter)
                .task {
                    let startTime = CFAbsoluteTimeGetCurrent()
                    await myObservations.fetchAll()
                    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                    debugPrint("Done fetching data. Elapsed time: \(timeElapsed) seconds.")
                    photosByDay = myObservations.photosByDay(calendarFilter: calendarFilter)
                }
                .onChange(of: calendarFilter) { oldFilter, newFilter in
                    if newFilter.year == nil || newFilter.year! > 1800 {
                        photosByDay = myObservations.photosByDay(calendarFilter: newFilter)
                    }
                }
        }
    }
}
