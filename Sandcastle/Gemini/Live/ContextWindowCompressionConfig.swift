//
//  ContextWindowCompressionConfig.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// Enables context window compression — a mechanism for managing the model's context window so that it does not exceed a given length.
///
/// <https://ai.google.dev/api/live#contextwindowcompressionconfig>
struct ContextWindowCompressionConfig {
    enum Mechanism {
        /// A sliding-window mechanism.
        case slidingWindow(SlidingWindow)
        /// The number of tokens (before running a turn) required to trigger a context window compression.
        ///
        /// This can be used to balance quality against latency as shorter context windows may result in faster model responses.
        /// However, any compression operation will cause a temporary latency increase, so they should not be triggered frequently.
        ///
        /// If not set, the default is 80% of the model's context window limit. This leaves 20% for the next user request/model response.
        case triggerTokens(Int64)
    }
    /// The context window compression mechanism used.
    let compressionMechanism: Mechanism
}

extension ContextWindowCompressionConfig: Codable {
    enum CodingKeys: String, CodingKey {
        // compressionMechanism
        case slidingWindow
        case triggerTokens
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let value = try container.decodeIfPresent(SlidingWindow.self, forKey: .slidingWindow) {
            self.compressionMechanism = .slidingWindow(value)
        } else if let value = try container.decodeIfPresent(Int64.self, forKey: .triggerTokens) {
            self.compressionMechanism = .triggerTokens(value)
        } else {
            let allKeys: [CodingKeys] = [.slidingWindow, .triggerTokens]
            let keysFormatted = allKeys
                .map { "'\($0.rawValue)'" }
                .joined(separator: ", ")
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Expected one of \(keysFormatted)"))
        }
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch compressionMechanism {
        case .slidingWindow(let value):
            try container.encode(value, forKey: .slidingWindow)
        case .triggerTokens(let value):
            try container.encode(value, forKey: .triggerTokens)
        }
    }
}
