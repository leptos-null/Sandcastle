//
//  IndirectOptional.swift
//  Sandcastle
//
//  Created by Leptos on 2/20/26.
//

import Foundation

/// `indirect` version of `Swift.Optional`.
///
/// This type should only be used if `Swift.Optional` is insufficient.
indirect enum IndirectOptional<Wrapped> {
    /// The absence of a value.
    case none
    /// The presence of a value, stored as `Wrapped`.
    case some(Wrapped)
}

extension IndirectOptional: ExpressibleByNilLiteral {
    init(nilLiteral: ()) {
        self = .none
    }
}

extension IndirectOptional: Equatable where Wrapped: Equatable {
}

extension IndirectOptional: Encodable where Wrapped: Encodable {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .none:
            try container.encodeNil()
        case .some(let wrapped):
            try container.encode(wrapped)
        }
    }
}

extension IndirectOptional: Decodable where Wrapped: Decodable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        do {
            let wrapped = try container.decode(Wrapped.self)
            self = .some(wrapped)
        } catch {
            if container.decodeNil() {
                self = .none
            } else {
                throw error
            }
        }
    }
}


extension IndirectOptional {
    init(swiftOptional: Swift.Optional<Wrapped>) {
        switch swiftOptional {
        case .none:
            self = .none
        case .some(let wrapped):
            self = .some(wrapped)
        }
    }
    
    var swiftOptional: Swift.Optional<Wrapped> {
        switch self {
        case .none: .none
        case .some(let wrapped): .some(wrapped)
        }
    }
}
