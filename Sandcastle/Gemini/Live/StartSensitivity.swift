//
//  StartSensitivity.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// Determines how start of speech is detected.
///
/// <https://ai.google.dev/api/live#startsensitivity>
enum StartSensitivity: String, Codable {
    /// The default is ``StartSensitivity/high``
    case unspecified = "START_SENSITIVITY_UNSPECIFIED"
    /// Automatic detection will detect the start of speech more often.
    case high = "START_SENSITIVITY_HIGH"
    /// Automatic detection will detect the start of speech less often.
    case low = "START_SENSITIVITY_LOW"
}
