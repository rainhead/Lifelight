//
//  iNaturalistAPI.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 10/29/24.
//

import Foundation

fileprivate let observationsBaseURL = URL(string: "https://api.inaturalist.org/v2/observations")!

struct INaturalistAPI {
    static let urlSession = {
        let urlSession = URLSession(configuration: .default)
        urlSession.configuration.urlCache?.diskCapacity = 256 * 1024 * 1024 // bytes
        return urlSession
    }()
    
    func fetchObservations(byUser userName: String, idAbove: Int?) async {
        var url = observationsBaseURL
        url.append(queryItems: [
            URLQueryItem(name: "fields", value: INaturalistObservation.fieldSpecification),
            URLQueryItem(name: "id_above", value: String(idAbove ?? 0)),
            URLQueryItem(name: "per_page", value: String(200)),
            URLQueryItem(name: "order_by", value: "id"),
            URLQueryItem(name: "order", value: "asc"),
            URLQueryItem(name: "user_id", value: userName)
        ])
        await fetchObservations(fromURL: url)
    }
    
    func fetchObservations(fromURL url: URL) async {
        let db = LLDatabase.shared
        let startTime = CFAbsoluteTimeGetCurrent()
        var nextPage: UInt? = 1
        while nextPage != nil {
            var url = url
            url.append(queryItems: [URLQueryItem(name: "page", value: String(nextPage!))])
            let page: PagedResponse<INaturalistObservation> = await fetch(url: url, urlSession: Self.urlSession)
            nextPage = page.nextPage
            db.receiveObservations(page.results)
        }
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        debugPrint("Done loading data. Elapsed time: \(timeElapsed) seconds.")
    }
}

nonisolated func fetch<T: Decodable>(url: URL, urlSession: URLSession) async -> T {
    var request = URLRequest(url: url)
    request.allowsCellularAccess = true
    request.allowsExpensiveNetworkAccess = false
    request.allowsConstrainedNetworkAccess = false
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
