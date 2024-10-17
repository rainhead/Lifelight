//
//  URLCache+imageCache.swift
//  Natgeist
//
//  Created by Peter Abrahamsen on 5/2/24.
//

import Foundation

extension URLCache {
    static let imageCache = URLCache(memoryCapacity: 32_000_000, diskCapacity: 512_000_000)
}
