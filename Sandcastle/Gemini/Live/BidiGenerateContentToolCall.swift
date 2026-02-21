//
//  BidiGenerateContentToolCall.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// Request for the client to execute the ``BidiGenerateContentToolCall/functionCalls`` and return the responses with the matching `id`s.
///
/// <https://ai.google.dev/api/live#bidigeneratecontenttoolcall>
struct BidiGenerateContentToolCall: Codable {
    /// Output only. The function call to be executed.
    let functionCalls: [FunctionCall]?
}
