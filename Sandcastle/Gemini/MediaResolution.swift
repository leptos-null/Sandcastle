//
//  MediaResolution.swift
//  Sandcastle
//
//  Created by Leptos on 2/20/26.
//

import Foundation

/// Media resolution for the input media.
///
/// <https://ai.google.dev/api/generate-content#MediaResolution>
enum MediaResolution: String, Codable {
    /// Media resolution has not been set.
    case unspecified = "MEDIA_RESOLUTION_UNSPECIFIED"
    /// Media resolution set to low (64 tokens).
    case low = "MEDIA_RESOLUTION_LOW"
    /// Media resolution set to medium (256 tokens).
    case medium = "MEDIA_RESOLUTION_MEDIUM"
    /// Media resolution set to high (zoomed reframing with 256 tokens).
    case high = "MEDIA_RESOLUTION_HIGH"
}
