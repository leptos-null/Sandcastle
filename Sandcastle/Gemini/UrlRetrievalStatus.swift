//
//  UrlRetrievalStatus.swift
//  Sandcastle
//
//  Created by Leptos on 2/20/26.
//

import Foundation

/// Status of the url retrieval.
///
/// <https://ai.google.dev/api/generate-content#UrlRetrievalStatus>
enum UrlRetrievalStatus: String, Codable {
    case unspecified = "URL_RETRIEVAL_STATUS_UNSPECIFIED"
    case success = "URL_RETRIEVAL_STATUS_SUCCESS"
    case error = "URL_RETRIEVAL_STATUS_ERROR"
    case paywall = "URL_RETRIEVAL_STATUS_PAYWALL"
    case unsafe = "URL_RETRIEVAL_STATUS_UNSAFE"
}
