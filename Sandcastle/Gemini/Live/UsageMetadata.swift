//
//  UsageMetadata.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// Usage metadata about response(s).
///
/// <https://ai.google.dev/api/live#usagemetadata>
struct UsageMetadata: Codable {
    /// Output only. Number of tokens in the prompt.
    ///
    /// When `cachedContent` is set, this is still the total effective prompt size meaning this includes the number of tokens in the cached content.
    let promptTokenCount: Int32
    /// Number of tokens in the cached part of the prompt (the cached content)
    let cachedContentTokenCount: Int32
    /// Output only. Total number of tokens across all the generated response candidates.
    let responseTokenCount: Int32
    /// Output only. Number of tokens present in tool-use prompt(s).
    let toolUsePromptTokenCount: Int32
    /// Output only. Number of tokens of thoughts for thinking models.
    let thoughtsTokenCount: Int32
    /// Output only. Total token count for the generation request (prompt + response candidates).
    let totalTokenCount: Int32
    
    /// Output only. List of modalities that were processed in the request input.
    let promptTokensDetails: [ModalityTokenCount]
    /// Output only. List of modalities of the cached content in the request input.
    let cacheTokensDetails: [ModalityTokenCount]
    /// Output only. List of modalities that were returned in the response.
    let responseTokensDetails: [ModalityTokenCount]
    /// Output only. List of modalities that were processed for tool-use request inputs.
    let toolUsePromptTokensDetails: [ModalityTokenCount]
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.promptTokenCount = try container.decodeIfPresent(Int32.self, forKey: .promptTokenCount) ?? 0
        self.cachedContentTokenCount = try container.decodeIfPresent(Int32.self, forKey: .cachedContentTokenCount) ?? 0
        self.responseTokenCount = try container.decodeIfPresent(Int32.self, forKey: .responseTokenCount) ?? 0
        self.toolUsePromptTokenCount = try container.decodeIfPresent(Int32.self, forKey: .toolUsePromptTokenCount) ?? 0
        self.thoughtsTokenCount = try container.decodeIfPresent(Int32.self, forKey: .thoughtsTokenCount) ?? 0
        self.totalTokenCount = try container.decodeIfPresent(Int32.self, forKey: .totalTokenCount) ?? 0
        
        self.promptTokensDetails = try container.decodeIfPresent([ModalityTokenCount].self, forKey: .promptTokensDetails) ?? []
        self.cacheTokensDetails = try container.decodeIfPresent([ModalityTokenCount].self, forKey: .cacheTokensDetails) ?? []
        self.responseTokensDetails = try container.decodeIfPresent([ModalityTokenCount].self, forKey: .responseTokensDetails) ?? []
        self.toolUsePromptTokensDetails = try container.decodeIfPresent([ModalityTokenCount].self, forKey: .toolUsePromptTokensDetails) ?? []
    }
}
