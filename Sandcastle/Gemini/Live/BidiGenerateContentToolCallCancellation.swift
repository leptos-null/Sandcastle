//
//  BidiGenerateContentToolCallCancellation.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// Notification for the client that a previously issued ToolCallMessage with the specified ids should not have been executed and should be cancelled.
///
/// If there were side-effects to those tool calls, clients may attempt to undo the tool calls. This message occurs only in cases where the clients interrupt server turns.
///
/// <https://ai.google.dev/api/live#bidigeneratecontenttoolcallcancellation>
struct BidiGenerateContentToolCallCancellation: Codable {
    /// Output only. The ids of the tool calls to be cancelled.
    let ids: [String]
}
