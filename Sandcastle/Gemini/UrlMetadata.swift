//
//  UrlMetadata.swift
//  Sandcastle
//
//  Created by Leptos on 2/20/26.
//

import Foundation

/// Context of the a single url retrieval.
///
/// <https://ai.google.dev/api/generate-content#UrlMetadata>
struct UrlMetadata: Codable {
    /// Retrieved url by the tool.
    let retrievedUrl: String
    /// Status of the url retrieval.
    let urlRetrievalStatus: UrlRetrievalStatus
}
