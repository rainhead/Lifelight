//
//  MyINaturalistObservations.swift
//  Natgeist
//
//  Created by Peter Abrahamsen on 10/10/24.
//

import Foundation
import Algorithms
import GRDB

class MyObservations: Equatable, Observable {
    static let urlSession = {
        let urlSession = URLSession(configuration: .default)
        urlSession.configuration.urlCache?.diskCapacity = 256 * 1024 * 1024 // bytes
        return urlSession
    }()
    
    static func == (lhs: MyObservations, rhs: MyObservations) -> Bool {
        lhs.userName == rhs.userName
    }
    
    let userName: String
    let db: LLDatabase = LLDatabase()
    
    init(userName: String) {
        self.userName = userName
    }
    
    func photosByDay() -> [(Date, [LLPhotoWithObservation].SubSequence)] {
        let rows = try! db.queue.read { db in
            let request = LLObservationPhoto.including(required: LLObservationPhoto.observation).order(sql: "coalesce(observedOn, observations.createdAt) DESC")
            return try LLPhotoWithObservation.fetchAll(db, request)
        }
        return rows.chunked(on: { $0.observation.observedOrCreatedOn })
    }
    
    func fetchAll() async {
        var nextPage: UInt? = 1
        while nextPage != nil {
            let url = url(forPage: nextPage!)
            let page: PagedResponse<INaturalistObservation> = await fetch(url: url, urlSession: MyObservations.urlSession)
            nextPage = page.nextPage
            receiveObservations(page.results)
        }
    }
    
    func loadFixture(named: String) {
        let fixtureURL = Bundle.main.url(forResource: "my_observations", withExtension: "json")!
        let page: PagedResponse<INaturalistObservation> = loadFixtureFrom(fixtureURL)
        receiveObservations(page.results)
    }
    
    func receiveObservations(_ observations: [INaturalistObservation]) {
        db.addTaxa(observations.compactMap(\.taxon).map(\.llTaxon))
        db.addObservations(observations.map(\.llObservation))
        db.addObservationPhotos(observations.flatMap(\.llObservationPhotos))
    }
    
    func url(forPage page: UInt) -> URL {
        var url = URL(string: "https://api.inaturalist.org/v2/observations")!
        url.append(queryItems: [
            URLQueryItem(name: "fields", value: INaturalistObservation.fieldSpecification),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(200)),
            URLQueryItem(name: "order_by", value: "observed_on"),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "user_id", value: userName)
        ])
        return url
    }
}


nonisolated func fetch<T: Decodable>(url: URL, urlSession: URLSession) async -> T {
    var request = URLRequest(url: url)
    request.allowsCellularAccess = true
    request.allowsExpensiveNetworkAccess = false
    request.allowsConstrainedNetworkAccess = false
    request.cachePolicy = .returnCacheDataElseLoad // !!!
    request.httpShouldUsePipelining = true
//    if let oauthToken {
//        request.addValue("Bearer \(oauthToken)", forHTTPHeaderField: "Authorization")
//    }
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let (data, response) = try! await urlSession.data(for: request) as! (Data, HTTPURLResponse)
    
    guard (200...299).contains(response.statusCode) else {
        fatalError("Unsuccessful response fetching \(url): \(data.debugDescription)")
    }
    if response.mimeType != "application/json" {
        fatalError("Unknown response type \(response.mimeType ?? "(none)") at \(url)")
    }
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse resource at \(url) as \(T.self):\n\(error)")
    }
}