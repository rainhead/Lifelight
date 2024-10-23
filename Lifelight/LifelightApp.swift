//
//  LifelightApp.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 10/17/24.
//

import SwiftUI

@main
struct LifelightApp: App {
    @State var userName = "rainhead"
    @State var observations = [(Date, [INaturalistObservation].SubSequence)]()
    @State var db = LLDatabase()
    
    var body: some Scene {
        WindowGroup {
            ContentView(observations: $observations)
                .task(id: userName) {
                    let startTime = CFAbsoluteTimeGetCurrent()
                    for await update in MyINaturalistObservations(userName: userName, db: db) {
                        debugPrint("Got update")
                        for (day, observations) in update {
                            if let index = self.observations.firstIndex(where: { $0.0 == day }) {
                                //                                debugPrint("Updating \(day)")
                                self.observations[index].1.append(contentsOf: observations)
                                self.observations[index].1.sort()
                            } else if let index = self.observations.firstIndex(where: { $0.0 < day }) {
                                //                                debugPrint("Inserting \(day) before \(self.observations[index].0)")
                                self.observations.insert((day, observations), at: index)
                            } else {
                                //                                debugPrint("Appending \(day)")
                                self.observations.append((day, observations))
                            }
                        }
                    }
                    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                    debugPrint("Done fetching data. Elapsed time: \(timeElapsed) seconds.")
                }
        }
    }
}
