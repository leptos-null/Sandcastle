//
//  BidiGenerateContentToolResponse.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// Client generated response to a ``ToolCall`` received from the server.
///
/// Individual ``FunctionResponse`` objects are matched to the respective ``FunctionCall`` objects by the `id` field.
///
/// Note that in the unary and server-streaming GenerateContent APIs function calling happens by exchanging the ``Content`` parts, while in the bidi GenerateContent APIs function calling happens over these dedicated set of messages.
///
/// <https://ai.google.dev/api/live#bidigeneratecontenttoolresponse>
struct BidiGenerateContentToolResponse: Codable {
    /// The response to the function calls.
    let functionResponses: [FunctionResponse]?
}
