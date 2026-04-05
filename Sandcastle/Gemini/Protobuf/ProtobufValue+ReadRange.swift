//
//  ProtobufValue+ReadRange.swift
//  Sandcastle
//
//  Created by Leptos on 4/5/26.
//

import Foundation

struct ProtobufValueRangeReadError<R: RangeExpression>: Swift.Error {
    let expected: R
    let found: R.Bound
    
    let path: [ProtobufValuePathComponent]
}

extension ProtobufValueContainer {
    func double<R: RangeExpression>(in range: R) throws -> R.Bound where R.Bound == Double {
        let number = try self.double()
        guard range ~= number else {
            throw ProtobufValueRangeReadError(expected: range, found: number, path: path)
        }
        return number
    }
    
    func integer<R: RangeExpression>(in range: R) throws -> R.Bound where R.Bound: BinaryInteger {
        let integer: R.Bound = try self.integer()
        guard range ~= integer else {
            throw ProtobufValueRangeReadError(expected: range, found: integer, path: path)
        }
        return integer
    }
}

extension ProtobufValueRangeReadError {
    // acts as an override for Foundations extension on Swift.Error with this variable name
    var localizedDescription: String {
        let stringyPath: String = ProtobufValuePathComponent.description(for: self.path)
        return "unsupported '\(stringyPath)' value"
    }
}
