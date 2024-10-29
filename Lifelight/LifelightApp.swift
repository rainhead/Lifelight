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
    @State var myObservations = MyObservations(userName: "rainhead")

    var body: some Scene {
        WindowGroup {
            ContentView(photosByDay: $photosByDay)
                .task {
                    let startTime = CFAbsoluteTimeGetCurrent()
                    await myObservations.fetchAll()
                    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                    debugPrint("Done fetching data. Elapsed time: \(timeElapsed) seconds.")
                    getPhotos()
                }
                .onChange(of: myObservations, getPhotos)
                .onChange(of: myObservations, getPhotos)
        }
    }
    
    func getPhotos() {
        photosByDay = myObservations.photosByDay()
    }
}
