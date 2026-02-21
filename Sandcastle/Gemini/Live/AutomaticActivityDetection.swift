//
//  AutomaticActivityDetection.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// Configures automatic detection of activity.
///
/// <https://ai.google.dev/api/live#automaticactivitydetection>
struct AutomaticActivityDetection: Codable {
    /// If enabled (the default), detected voice and text input count as activity.
    /// If disabled, the client must send activity signals.
    let disabled: Bool?
    /// Determines how likely speech is to be detected.
    let startOfSpeechSensitivity: StartSensitivity?
    /// The required duration of detected speech before start-of-speech is committed.
    ///
    /// The lower this value, the more sensitive the start-of-speech detection is and shorter speech can be recognized.
    /// However, this also increases the probability of false positives.
    let prefixPaddingMs: Int32?
    /// Determines how likely detected speech is ended.
    let endOfSpeechSensitivity: EndSensitivity?
    /// The required duration of detected non-speech (e.g. silence) before end-of-speech is committed.
    ///
    /// The larger this value, the longer speech gaps can be without interrupting the user's activity but this will increase the model's latency.
    let silenceDurationMs: Int32?
}
