//
//  FileData.swift
//  Sandcastle
//
//  Created by Leptos on 2/21/26.
//

import Foundation

/// URI based data.
///
/// <https://ai.google.dev/api/caching#FileData>
struct FileData: Codable {
    /// The IANA standard MIME type of the source data.
    let mimeType: String?
    /// URI.
    let fileUri: String
}
