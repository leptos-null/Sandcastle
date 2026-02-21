//
//  PrebuiltVoiceConfig.swift
//  Sandcastle
//
//  Created by Leptos on 2/20/26.
//

import Foundation

/// The configuration for the prebuilt speaker to use.
///
/// <https://ai.google.dev/api/generate-content#PrebuiltVoiceConfig>
struct PrebuiltVoiceConfig: Codable {
    /// The name of the preset voice to use.
    let voiceName: String
}
