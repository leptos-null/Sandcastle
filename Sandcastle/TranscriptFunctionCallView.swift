//
//  TranscriptFunctionCallView.swift
//  Sandcastle
//
//  Created by Leptos on 2/27/26.
//

import SwiftUI
import Gemini

struct TranscriptFunctionCallView: View {
    let functionCall: FunctionCall
    
    private func attributedStringForValue(_ value: Protobuf.Value, indentation: Int) -> AttributedString {
        var attributes = AttributeContainer()
        switch value {
        case .string(let string):
            attributes.swiftUI.foregroundColor = .orange
            return .init("\"\(string)\"", attributes: attributes)
        case .number(let double):
            attributes.swiftUI.foregroundColor = .purple
            return .init(String(double), attributes: attributes)
        case .bool(let bool):
            attributes.swiftUI.foregroundColor = .pink
            return .init(String(bool), attributes: attributes)
        case .array(let array):
            var build = AttributedString("[\n")
            
            for (entry, isLast) in array.taggedWithIsLast() {
                build.append(AttributedString(String(repeating: "\t", count: indentation + 1)))
                build.append(attributedStringForValue(entry, indentation: indentation + 1))
                build.append(AttributedString(isLast ? "\n" : ",\n"))
            }
            build.append(AttributedString(String(repeating: "\t", count: indentation)))
            build.append(AttributedString("]"))
            return build
        case .dictionary(let dictionary):
            // used for keys
            attributes.swiftUI.foregroundColor = .orange
            
            var build = AttributedString("{\n")
            
            // sort for stability
            let keys = dictionary.keys.sorted()
            for (key, isLast) in keys.taggedWithIsLast() {
                build.append(AttributedString(String(repeating: "\t", count: indentation + 1)))
                build.append(AttributedString("\"\(key)\"", attributes: attributes))
                build.append(AttributedString(": "))
                build.append(attributedStringForValue(dictionary[key]!, indentation: indentation + 1))
                build.append(AttributedString(isLast ? "\n" : ",\n"))
            }
            build.append(AttributedString(String(repeating: "\t", count: indentation)))
            build.append(AttributedString("}"))
            return build
        case .null:
            attributes.swiftUI.foregroundColor = .pink
            return .init("null", attributes: attributes)
        }
    }
    
    private func attributedCallDescription() -> AttributedString {
        var build = AttributedString("\(functionCall.name)(")
        build.append(attributedStringForValue(.dictionary(functionCall.args ?? [:]), indentation: 0))
        build.append(AttributedString(")"))
        return build
    }
    
    var body: some View {
        TranscriptEntryView {
            VStack(alignment: .leading, spacing: 12) {
                if let id = functionCall.id {
                    Text(id)
                        .font(.footnote)
                        .monospaced()
                        .foregroundStyle(.secondary)
                }
                
                Text(attributedCallDescription())
                    .font(.callout)
                    .monospaced()
                
                Label("Function Call", systemImage: "curlybraces")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private extension Collection {
    func taggedWithIsLast() -> [(element: Element, isLast: Bool)] {
        let lastOffset: Int = self.count - 1
        return self
            .enumerated()
            .map { offset, element in
                return (element, offset == lastOffset)
            }
    }
}

#Preview {
    TranscriptFunctionCallView(functionCall: .init(id: "function-call-123abc", name: "get_weather", args: [
        "location": .dictionary([
            // Googleplex
            "latitude": .number(37.422339),
            "longitude": .number(-122.084370),
        ]),
        "attributes": .array([
            .string("temperature"),
            .string("humidity")
        ]),
        "preferences": .null,
        "include_forecast": .bool(false)
    ]))
}
