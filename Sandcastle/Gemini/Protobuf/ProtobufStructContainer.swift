//
//  ProtobufStructContainer.swift
//  Sandcastle
//
//  Created by Leptos on 4/4/26.
//

import Foundation
import Gemini

struct ProtobufStructContainer {
    let underlying: Protobuf.Struct
    
    let path: [ProtobufValuePathComponent]
    
    init(underlying: Protobuf.Struct, path: [ProtobufValuePathComponent] = []) {
        self.underlying = underlying
        self.path = path
    }
    
    func value(for key: String) -> ProtobufValueContainer {
        let underlyingValue = underlying[key] ?? .null
        var newPath = path
        newPath.append(.key(key))
        return .init(underlying: underlyingValue, path: newPath)
    }
}

enum ProtobufValueType: Hashable, Sendable {
    case string
    case number
    case bool
    case array
    case dictionary
    case null
}

struct ProtobufValueContainer {
    let underlying: Protobuf.Value
    
    let path: [ProtobufValuePathComponent]
}

struct ProtobufValueReadError: Swift.Error {
    let expected: ProtobufValueType
    let found: Protobuf.Value
    
    let path: [ProtobufValuePathComponent]
}

extension ProtobufValueContainer {
    func string() throws(ProtobufValueReadError) -> String {
        guard case .string(let string) = underlying else {
            throw .init(expected: .string, found: underlying, path: path)
        }
        return string
    }
    
    func double() throws(ProtobufValueReadError) -> Double {
        guard case .number(let double) = underlying else {
            throw .init(expected: .number, found: underlying, path: path)
        }
        return double
    }
    
    func bool() throws(ProtobufValueReadError) -> Bool {
        guard case .bool(let bool) = underlying else {
            throw .init(expected: .bool, found: underlying, path: path)
        }
        return bool
    }
    
    func array() throws(ProtobufValueReadError) -> [Self] {
        guard case .array(let array) = underlying else {
            throw .init(expected: .array, found: underlying, path: path)
        }
        return array.enumerated().map { (offset, element) in
            var newPath = path
            newPath.append(.index(offset))
            return .init(underlying: element, path: newPath)
        }
    }
    
    func dictionary() throws(ProtobufValueReadError) -> ProtobufStructContainer {
        guard case .dictionary(let dictionary) = underlying else {
            throw .init(expected: .dictionary, found: underlying, path: path)
        }
        return .init(underlying: dictionary, path: path)
    }
}

extension ProtobufValueContainer {
    func accessIfPresent<T, E>(_ read: (Self) throws(E) -> T) throws(E) -> T? {
        if case .null = underlying { return nil }
        
        return try read(self)
    }
}

extension ProtobufValueContainer {
    func integer<T: BinaryInteger>() throws(ProtobufValueReadError) -> T {
        let floatingPoint = try self.double()
        return .init(floatingPoint)
    }
}

extension ProtobufValueReadError {
    // acts as an override for Foundations extension on Swift.Error with this variable name
    var localizedDescription: String {
        let stringyPath: String = ProtobufValuePathComponent.description(for: self.path)
        
        if case .null = self.found {
            return "missing '\(stringyPath)' parameter"
        }
        return "unsupported '\(stringyPath)' value"
    }
}
