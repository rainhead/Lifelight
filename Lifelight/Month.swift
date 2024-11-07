//
//  Month.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 11/7/24.
//

import GRDB

enum Month: Int, Equatable, Identifiable, CaseIterable, SQLExpressible {
    case january = 1
    case february = 2
    case march = 3
    case april = 4
    case may = 5
    case june = 6
    case july = 7
    case august = 8
    case september = 9
    case october = 10
    case november = 11
    case december = 12
    
    var id: Self { self }
    
    var asString: String {
        switch self {
        case .january: "January"
        case .february: "February"
        case .march: "March"
        case .april: "April"
        case .may: "May"
        case .june: "June"
        case .july: "July"
        case .august: "August"
        case .september: "September"
        case .october: "October"
        case .november: "November"
        case .december: "December"
        }
    }
}
