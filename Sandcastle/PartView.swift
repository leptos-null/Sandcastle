//
//  PartView.swift
//  Sandcastle
//
//  Created by Leptos on 2/25/26.
//

import SwiftUI

struct PartView: View {
    let part: Part
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundStyle: some ShapeStyle {
        let opacity: Double = switch colorScheme {
        case .light: 0.125
        case .dark: 0.25
        @unknown default: 0.15
        }
        return .secondary.opacity(opacity)
    }
    
    private func bestEffortMarkdown(text: String) -> Text {
        do {
            let attributedString = try AttributedString(markdown: text, options: .init(
                allowsExtendedAttributes: false,
                interpretedSyntax: .inlineOnlyPreservingWhitespace,
                failurePolicy: .returnPartiallyParsedIfPossible
            ))
            return Text(attributedString)
        } catch {
            return Text(text)
        }
    }
    
    var body: some View {
        Group {
            switch part.data {
            case .text(let textPart) where part.thought == true:
                // only "thought" text (that we know of) can have markdown syntax,
                // so, as an optimization, only try parsing as markdown for these.
                // I've also noticed that "thought" text seems to have extra line breaks,
                // so trim those
                bestEffortMarkdown(text: textPart.trimmingCharacters(in: .newlines))
                    .foregroundStyle(.primary.opacity(0.75))
            case .text(let textPart):
                Text(textPart)
                    .foregroundStyle(.primary)
            default:
                Text("Unsupported data type")
                    .foregroundStyle(.red)
            }
        }
        .padding(12)
        .background(backgroundStyle, in: .rect(cornerRadius: 12))
    }
}

#Preview("Standard text") {
    PartView(part: .init(
        thought: nil, thoughtSignature: nil,
        partMetadata: nil, data: .text("How tall is the Eiffel Tower?"), metadata: nil
    ))
    .scenePadding()
}

#Preview("Thought text") {
    // copy and pasted from a real query
    PartView(part: .init(
        thought: true, thoughtSignature: nil,
        partMetadata: nil, data: .text("**Answering the Inquiry**\n\nI have received a simple, factual question about the Eiffel Tower's height. My current thinking is to provide a straightforward, calm response that simply states the tower's height and mentions the antenna. I will prioritize direct information over any emotional embellishment, given the user's neutral tone.\n\n\n"), metadata: nil
    ))
    .scenePadding()
}
