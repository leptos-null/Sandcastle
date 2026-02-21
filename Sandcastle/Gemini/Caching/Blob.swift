//
//  Blob.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// Raw media bytes.
///
/// Text should not be sent as raw bytes, use the 'text' field.
///
/// <https://ai.google.dev/api/caching#Blob>
struct Blob: Codable {
    /// The IANA standard MIME type of the source data.
    ///
    /// Examples:
    /// - image/png
    /// - image/jpeg
    ///
    /// If an unsupported MIME type is provided, an error will be returned.
    /// For a complete list of supported types, see [Supported file formats](<https://ai.google.dev/gemini-api/docs/prompting_with_media#supported_file_formats>).
    let mimeType: String
    /// Raw bytes for media formats.
    ///
    /// A base64-encoded string.
    let data: String
}
