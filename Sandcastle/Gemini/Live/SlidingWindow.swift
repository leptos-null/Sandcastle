//
//  SlidingWindow.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// The SlidingWindow method operates by discarding content at the beginning of the context window.
/// The resulting context will always begin at the start of a USER role turn.
/// System instructions and any ``BidiGenerateContentSetup/prefixTurns`` will always remain at the beginning of the result.
///
/// <https://ai.google.dev/api/live#slidingwindow>
struct SlidingWindow: Codable {
    /// The target number of tokens to keep.
    ///
    /// The default value is `trigger_tokens/2`.
    ///
    /// Discarding parts of the context window causes a temporary latency increase so this value should be calibrated to avoid frequent compression operations.
    let targetTokens: Int64
}
