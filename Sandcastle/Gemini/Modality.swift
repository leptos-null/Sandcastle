//
//  Modality.swift
//  Sandcastle
//
//  Created by Leptos on 2/20/26.
//

import Foundation

/// Content Part modality
///
/// <https://ai.google.dev/api/generate-content#Modality>
enum Modality: String, Codable {
    /// Unspecified modality.
    case unspecified = "MODALITY_UNSPECIFIED"
    /// Plain text.
    case text = "TEXT"
    /// Image.
    case image = "IMAGE"
    /// Video.
    case video = "VIDEO"
    /// Audio.
    case audio = "AUDIO"
    /// Document, e.g. PDF.
    case document = "DOCUMENT"
}
