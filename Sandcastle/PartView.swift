//
//  PartView.swift
//  Sandcastle
//
//  Created by Leptos on 2/25/26.
//

import SwiftUI
import Gemini

struct PartView: View {
    let part: Part
    
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
        TranscriptEntryView {
            switch part.data {
            case .text(let textPart) where part.thought == true:
                VStack(alignment: .leading, spacing: 12) {
                    // only "thought" text (that we know of) can have markdown syntax,
                    // so, as an optimization, only try parsing as markdown for these.
                    // I've also noticed that "thought" text seems to have extra line breaks,
                    // so trim those
                    bestEffortMarkdown(text: textPart.trimmingCharacters(in: .newlines))
                        .foregroundStyle(.primary.opacity(0.75))
                    
                    Label("Thought", systemImage: "brain")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .text(let textPart):
                Text(textPart)
                    .foregroundStyle(.primary)
            default:
                Text("Unsupported data type")
                    .foregroundStyle(.red)
            }
        }
    }
}

#Preview("Standard text") {
    PartView(part: .init(
        data: .text("How tall is the Eiffel Tower?")
    ))
    .scenePadding()
}

#Preview("Thought text") {
    // copy and pasted from a real query
    PartView(part: .init(
        thought: true,
        data: .text("**Answering the Inquiry**\n\nI have received a simple, factual question about the Eiffel Tower's height. My current thinking is to provide a straightforward, calm response that simply states the tower's height and mentions the antenna. I will prioritize direct information over any emotional embellishment, given the user's neutral tone.\n\n\n")
    ))
    .scenePadding()
}
