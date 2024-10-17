//
//  INaturalistControlledValue.swift
//  Natgeist
//
//  Created by Peter Abrahamsen on 10/9/24.
//

import Foundation

struct INaturalistControlledValue: Equatable, Decodable, Identifiable {
    static let female: Self = .init(id: 10, label: "Female")
    static let male: Self = .init(id: 11, label: "Male")
    
    let id: UInt64
    let label: String
    
    static func == (lhs: INaturalistControlledValue, rhs: INaturalistControlledValue) -> Bool {
        lhs.id == rhs.id
    }
}
