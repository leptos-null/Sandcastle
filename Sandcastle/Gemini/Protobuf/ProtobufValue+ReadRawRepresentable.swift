//
//  ProtobufValue+ReadRawRepresentable.swift
//  Sandcastle
//
//  Created by Leptos on 4/5/26.
//

struct ProtobufValueRawRepresentableReadError<T: RawRepresentable>: Swift.Error {
    let found: T.RawValue
    
    let path: [ProtobufValuePathComponent]
}

extension ProtobufValueContainer {
    func rawRepresentable<T: RawRepresentable>() throws -> T where T.RawValue == String {
        let string = try self.string()
        guard let representable = T.init(rawValue: string) else {
            throw ProtobufValueRawRepresentableReadError<T>(found: string, path: path)
        }
        return representable
    }
}

extension ProtobufValueRawRepresentableReadError {
    // acts as an override for Foundations extension on Swift.Error with this variable name
    var localizedDescription: String {
        let stringyPath: String = ProtobufValuePathComponent.description(for: self.path)
        return "unsupported '\(stringyPath)' value"
    }
}
