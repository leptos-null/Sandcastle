//
//  UrlContextMetadata.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// Metadata related to url context retrieval tool.
///
/// <https://ai.google.dev/api/live#urlcontextmetadata>
struct UrlContextMetadata: Codable {
    /// List of url context.
    let urlMetadata: [UrlMetadata]
}
