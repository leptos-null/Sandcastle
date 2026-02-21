//
//  Protobuf.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

// namespace
enum Protobuf {}

extension Protobuf {
    /// A `Duration` represents a signed, fixed-length span of time represented as seconds.
    ///
    /// - Note: This type is designed to be `Codable` compliant with the Protobuf `Duration` type (linked below),
    /// however this type is not API compliant
    ///
    /// <https://protobuf.dev/reference/protobuf/google.protobuf/#duration>
    struct Duration: Codable, RawRepresentable {
        var rawValue: TimeInterval
        
        init(rawValue: TimeInterval) {
            self.rawValue = rawValue
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            var string = try container.decode(String.self)
            guard string.popLast() == "s" else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Protobuf.Duration must end in 's'")
            }
            guard let seconds = TimeInterval(string) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Protobuf.Duration must start with a valid number")
            }
            self.rawValue = seconds
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode("\(rawValue)s")
        }
    }
}
