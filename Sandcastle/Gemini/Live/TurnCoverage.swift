//
//  TurnCoverage.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// Options about which input is included in the user's turn.
///
/// <https://ai.google.dev/api/live#turncoverage>
enum TurnCoverage: String, Codable {
    /// If unspecified, the default behavior is ``TurnCoverage/onlyActivity``.
    case unspecified = "TURN_COVERAGE_UNSPECIFIED"
    /// The users turn only includes activity since the last turn, excluding inactivity (e.g. silence on the audio stream). This is the default behavior.
    case onlyActivity = "TURN_INCLUDES_ONLY_ACTIVITY"
    /// The users turn includes all realtime input since the last turn, including inactivity (e.g. silence on the audio stream).
    case allInput = "TURN_INCLUDES_ALL_INPUT"
}
