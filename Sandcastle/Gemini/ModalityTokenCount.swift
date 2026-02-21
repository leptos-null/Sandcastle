//
//  ModalityTokenCount.swift
//  Sandcastle
//
//  Created by Leptos on 2/20/26.
//

import Foundation

/// Represents token counting info for a single modality.
///
/// <https://ai.google.dev/api/generate-content#modalitytokencount>
struct ModalityTokenCount: Codable {
    /// The modality associated with this token count.
    let modality: Modality
    /// Number of tokens.
    let tokenCount: Int
}
