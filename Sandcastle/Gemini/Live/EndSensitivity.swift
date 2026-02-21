//
//  EndSensitivity.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// Determines how end of speech is detected.
///
/// <https://ai.google.dev/api/live#endsensitivity>
enum EndSensitivity: String, Codable {
    /// The default is ``EndSensitivity/high``
    case unspecified = "END_SENSITIVITY_UNSPECIFIED"
    /// Automatic detection ends speech more often.
    case high = "END_SENSITIVITY_HIGH"
    /// Automatic detection ends speech less often.
    case low = "END_SENSITIVITY_LOW"
}
