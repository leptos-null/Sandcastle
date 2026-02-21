//
//  BidiGenerateContentTranscription.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// Transcription of audio (input or output).
///
/// <https://ai.google.dev/api/live#bidigeneratecontenttranscription>
struct BidiGenerateContentTranscription: Codable {
    /// Transcription text.
    let text: String
}
