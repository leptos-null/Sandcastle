//
//  VoiceConfig.swift
//  Sandcastle
//
//  Created by Leptos on 2/20/26.
//

import Foundation

/// The configuration for the voice to use.
///
/// <https://ai.google.dev/api/generate-content#VoiceConfig>
struct VoiceConfig {
    enum Value {
        /// The configuration for the prebuilt voice to use.
        case prebuiltVoiceConfig(PrebuiltVoiceConfig)
    }
    /// The configuration for the speaker to use.
    let value: Value
}

extension VoiceConfig: Codable {
    enum CodingKeys: String, CodingKey {
        // value
        case prebuiltVoiceConfig
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let value = try container.decodeIfPresent(PrebuiltVoiceConfig.self, forKey: .prebuiltVoiceConfig) {
            self.value = .prebuiltVoiceConfig(value)
        } else {
            let allKeys: [CodingKeys] = [.prebuiltVoiceConfig]
            let keysFormatted = allKeys
                .map { "'\($0.rawValue)'" }
                .joined(separator: ", ")
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Expected one of \(keysFormatted)"))
        }
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch value {
        case .prebuiltVoiceConfig(let value):
            try container.encode(value, forKey: .prebuiltVoiceConfig)
        }
    }
}
