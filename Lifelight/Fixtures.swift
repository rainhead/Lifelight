//
//  Fixtures.swift
//  Natgeist
//
//  Created by Peter Abrahamsen on 6/4/24.
//

import Foundation

func loadFixtureFrom<T: Decodable>(_ url: URL) -> T {
    let decoder = JSONDecoder()
    let data = try! Data(contentsOf: url)
    return try! decoder.decode(T.self, from: data)
}
