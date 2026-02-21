//
//  AnyJson.swift
//  Sandcastle
//
//  Created by Leptos on 2/20/26.
//

import Foundation

// this is not explicitly defined by the Gemini API, however we sometimes need to interact with some-what arbitrary objects
enum AnyJson: Codable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([AnyJson])
    case dictionary([String: AnyJson])
    
    case null
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([AnyJson].self) {
            self = .array(array)
        } else if let dictionary = try? container.decode([String: AnyJson].self) {
            self = .dictionary(dictionary)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected a string, number, bool, array, or dictionary")
        }
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let string):
            try container.encode(string)
        case .number(let number):
            try container.encode(number)
        case .bool(let bool):
            try container.encode(bool)
        case .array(let array):
            try container.encode(array)
        case .dictionary(let dictionary):
            try container.encode(dictionary)
        case .null:
            try container.encodeNil()
        }
    }
}
