//
//  ThinkingLevel.swift
//  Sandcastle
//
//  Created by Leptos on 2/20/26.
//

import Foundation

/// Allow user to specify how much to think using enum instead of integer budget.
///
/// <https://ai.google.dev/api/generate-content#ThinkingLevel>
enum ThinkingLevel: String, Codable {
    case unspecified = "THINKING_LEVEL_UNSPECIFIED"
    case minimal = "MINIMAL"
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
}
