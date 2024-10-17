//
//  PagedResponse.swift
//  Natgeist
//
//  Created by Peter Abrahamsen on 5/1/24.
//

import Foundation


struct PagedResponse<Result: Decodable>: Decodable {
    var total_results: UInt
    var page: UInt
    var per_page: UInt
    var results: [Result]
    var nextPage: UInt? {
        let (q, r) = total_results.quotientAndRemainder(dividingBy: per_page)
        let totalPages = q + (r > 0 ? 1 : 0)
        if totalPages > page {
            return page + 1
        } else {
            return nil
        }
    }
}
