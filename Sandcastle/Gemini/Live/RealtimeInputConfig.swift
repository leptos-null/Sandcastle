//
//  RealtimeInputConfig.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// Configures the realtime input behavior in ``BidiGenerateContent``.
///
/// <https://ai.google.dev/api/live#realtimeinputconfig>
struct RealtimeInputConfig: Codable {
    /// If not set, automatic activity detection is enabled by default.
    /// If automatic voice detection is disabled, the client must send activity signals.
    let automaticActivityDetection: AutomaticActivityDetection?
    /// Defines what effect activity has.
    let activityHandling: ActivityHandling?
    /// Defines which input is included in the user's turn.
    let turnCoverage: TurnCoverage?
}
