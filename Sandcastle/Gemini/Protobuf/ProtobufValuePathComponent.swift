//
//  ProtobufValuePathComponent.swift
//  Sandcastle
//
//  Created by Leptos on 4/5/26.
//

enum ProtobufValuePathComponent: Hashable, Sendable {
    case key(String)
    case index(Int)
}

extension ProtobufValuePathComponent {
    static func description<S: Sequence>(for path: S) -> String where S.Element == Self {
        path.reduce(into: "") { partialResult, pathComponent in
            switch pathComponent {
            case .key(let key):
                if !partialResult.isEmpty {
                    partialResult.append(".")
                }
                partialResult.append(key)
            case .index(let index):
                partialResult.append("[")
                partialResult.append(String(index))
                partialResult.append("]")
            }
        }
    }
}
