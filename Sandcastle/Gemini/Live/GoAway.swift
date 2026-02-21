//
//  GoAway.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// A notice that the server will soon disconnect.
///
/// <https://ai.google.dev/api/live#goaway>
struct GoAway: Codable {
    /// The remaining time before the connection will be terminated as ABORTED.
    ///
    /// This duration will never be less than a model-specific minimum, which will be specified together with the rate limits for the model.
    let timeLeft: Protobuf.Duration
}
