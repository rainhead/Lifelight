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
    @State var photosByDay = [(Date, [LLPhotoWithObservation].SubSequence)]()
    
    var body: some Scene {
        WindowGroup {
            ContentView(photosByDay: $photosByDay)
                .task(id: userName) {
                    let startTime = CFAbsoluteTimeGetCurrent()
                    let db = LLDatabase()
                    let myObservations = MyINaturalistObservations(userName: userName, db: db)
                    await myObservations.fetchAll()
                    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                    debugPrint("Done fetching data. Elapsed time: \(timeElapsed) seconds.")
                    photosByDay = myObservations.photosByDay()
                }
        }
    }
}
