//
//  INaturalistUser.swift
//  Natgeist
//
//  Created by Peter Abrahamsen on 10/9/24.
//

import Foundation

struct INaturalistUser: Equatable, Decodable, Identifiable {
    static let fieldSpecification = "(created_at:!t,id:!t,icon:!t,icon_url:!t,login:!t,name:!t)"

    let id: UInt64
    let login: String
    let name: String?
    
    private let icon: URL? // thumb, maximum dimension 100px
    private let icon_url: URL? // medium, maximum dimension 500px
    var largeURL: URL? { icon_url != nil ? URL(string: "large.\(icon_url!.pathExtension)", relativeTo: icon_url) : nil } // max dimension 1024px
    var mediumURL: URL? { icon_url } // max dimension 500px
    var originalURL: URL? { icon_url != nil ? URL(string: "original.\(icon_url!.pathExtension)", relativeTo: icon_url) : nil } // max dimension 2048px
    var smallURL: URL? { icon_url != nil ? URL(string: "small.\(icon_url!.pathExtension)", relativeTo: icon_url): nil } // max dimension 240px
    // no square URL; they're all square
    var thumbURL: URL? { icon } // max dimension 100px

    @DateFormatted<ISO8601DateStrategy> var created_at: Date
//    @DateFormatted<ISO8601DateStrategy> var updated_at: Date
}
