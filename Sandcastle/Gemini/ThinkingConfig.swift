//
//  ThinkingConfig.swift
//  Sandcastle
//
//  Created by Leptos on 2/20/26.
//

import Foundation

/// Config for thinking features.
///
/// <https://ai.google.dev/api/generate-content#ThinkingConfig>
struct ThinkingConfig: Codable {
    /// Indicates whether to include thoughts in the response.
    ///
    /// If true, thoughts are returned only when available.
    let includeThoughts: Bool?
    /// The number of thoughts tokens that the model should generate.
    let thinkingBudget: Int?
    /// Controls the maximum depth of the model's internal reasoning process before it produces a response.
    ///
    /// If not specified, the default is ``ThinkingLevel/high``.
    /// Recommended for Gemini 3 or later models. Use with earlier models results in an error.
    let thinkingLevel: ThinkingLevel?
    
    init(includeThoughts: Bool? = nil, thinkingBudget: Int? = nil, thinkingLevel: ThinkingLevel? = nil) {
        self.includeThoughts = includeThoughts
        self.thinkingBudget = thinkingBudget
        self.thinkingLevel = thinkingLevel
    }
}
