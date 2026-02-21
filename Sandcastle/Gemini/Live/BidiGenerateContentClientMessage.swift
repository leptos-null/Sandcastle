//
//  BidiGenerateContentClientMessage.swift
//  Sandcastle
//
//  Created by Leptos on 2/20/26.
//

import Foundation

/// <https://ai.google.dev/api/live#send-messages>
enum BidiGenerateContentClientMessage {
    /// Session configuration to be sent in the first message
    case setup(BidiGenerateContentSetup)
    /// Incremental content update of the current conversation delivered from the client
    case clientContent(BidiGenerateContentClientContent)
    /// Real time audio, video, or text input
    case realtimeInput(BidiGenerateContentRealtimeInput)
    /// Response to a ``BidiGenerateContentToolCall`` received from the server
    case toolResponse(BidiGenerateContentToolResponse)
}

extension BidiGenerateContentClientMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case setup
        case clientContent
        case realtimeInput
        case toolResponse
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if container.contains(.setup) {
            self = .setup(try container.decode(BidiGenerateContentSetup.self, forKey: .setup))
        } else if container.contains(.clientContent) {
            self = .clientContent(try container.decode(BidiGenerateContentClientContent.self, forKey: .clientContent))
        } else if container.contains(.realtimeInput) {
            self = .realtimeInput(try container.decode(BidiGenerateContentRealtimeInput.self, forKey: .realtimeInput))
        } else if container.contains(.toolResponse) {
            self = .toolResponse(try container.decode(BidiGenerateContentToolResponse.self, forKey: .toolResponse))
        } else {
            let allKeys: [CodingKeys] = [.setup, .clientContent, .realtimeInput, .toolResponse]
            let keysFormatted = allKeys
                .map { "'\($0.rawValue)'" }
                .joined(separator: ", ")
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Expected one of \(keysFormatted)"))
        }
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .setup(let bidiGenerateContentSetup):
            try container.encode(bidiGenerateContentSetup, forKey: .setup)
        case .clientContent(let bidiGenerateContentClientContent):
            try container.encode(bidiGenerateContentClientContent, forKey: .clientContent)
        case .realtimeInput(let bidiGenerateContentRealtimeInput):
            try container.encode(bidiGenerateContentRealtimeInput, forKey: .realtimeInput)
        case .toolResponse(let bidiGenerateContentToolResponse):
            try container.encode(bidiGenerateContentToolResponse, forKey: .toolResponse)
        }
    }
}
