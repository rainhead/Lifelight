//
//  LifelightApp.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 10/17/24.
//

import SwiftUI
import Combine

@main
struct LifelightApp: App {
    @State var userName = "rainhead"
    @State var iNaturalistAPI = INaturalistAPI()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear() {
                    Task {
                        await iNaturalistAPI.fetchObservations(byUser: userName)
                    }
                }
        }
    }
}
