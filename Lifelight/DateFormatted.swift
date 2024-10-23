//
//  DateFormatted.swift
//  Natgeist
//
//  Created by Peter Abrahamsen on 10/9/24.
//

import Foundation

protocol CodingStrategy {
    associatedtype RawValue: Decodable
    associatedtype WrappedValue: Equatable, Hashable

    static func decode(_ value: RawValue) -> WrappedValue
}

/// Uses a format to decode a date from Codable.
@propertyWrapper struct DateFormatted<T: CodingStrategy>: Decodable, Equatable, Hashable {
    static func == (lhs: DateFormatted<T>, rhs: DateFormatted<T>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
    
    func hash(into hasher: inout Hasher) {
        wrappedValue.hash(into: &hasher)
    }
    
    var wrappedValue: T.WrappedValue
    
    public init(from decoder: Decoder) throws {
        let value = try T.RawValue(from: decoder)
        self.wrappedValue = T.decode(value)
    }
}

private let formatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    return formatter
}()

struct ISO8601DateStrategy: CodingStrategy {
    static func decode(_ value: String) -> Date {
        return formatter.date(from: value)!
    }
}

struct OptionalISO8601DateStrategy: CodingStrategy {
    static func decode(_ value: String?) -> Date? {
        guard let value else { return nil }
        return ISO8601DateStrategy.decode(value)
    }
}
