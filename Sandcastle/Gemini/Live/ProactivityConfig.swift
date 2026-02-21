//
//  ProactivityConfig.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// Config for proactivity features.
///
/// <https://ai.google.dev/api/live#proactivityconfig>
struct ProactivityConfig: Codable {
    /// If enabled, the model can reject responding to the last prompt.
    ///
    /// For example, this allows the model to ignore out of context speech or to stay silent if the user did not make a request, yet.
    let proactiveAudio: Bool?
}
