//
//  DiscordFunctionProvider.swift
//  Sandcastle
//
//  Created by Leptos on 3/24/26.
//

import Foundation
import Gemini

class DiscordFunctionProvider: LiveSessionManager.Tools.FunctionProvider {
    private let urlSession: URLSession
    
    let functionDeclarations: [FunctionDeclaration] = [
        // per https://docs.discord.com/developers/resources/webhook#execute-webhook
        .init(
            name: "discord_send_message", description: "Send a message to a Discord channel via webhook",
            behavior: nil, parameters: .object(properties: [
                "content": .string(description: "the message contents (up to 2000 characters)"),
                "username": .string(description: "override the default username of the webhook", nullable: true),
            ]), parametersJsonSchema: nil, response: nil, responseJsonSchema: nil
        ),
    ]
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    private func handleSendMessageCall(parameters: ProtobufStructContainer) async -> Protobuf.Struct {
        do {
            let content: String = try parameters.value(for: "content").string()
            let username: String? = try parameters.value(for: "username").accessIfPresent { try $0.string() }
            
            var bodyFields: Protobuf.Struct = [
                "content": .string(content)
            ]
            if let username {
                bodyFields["username"] = .string(username)
            }
            
            let encoder = JSONEncoder()
            let body = try encoder.encode(bodyFields)
            
            guard let webhookURL = URL(string: Config.discordWebhook) else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: webhookURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
            
            let (_, urlResponse) = try await urlSession.data(for: request)
            
            if let httpResponse = urlResponse as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
                return [
                    "error": .string("server returned status: \(httpResponse.statusCode)")
                ]
            }
            
            return [
                "status": .string("success")
            ]
        } catch {
            return [
                "error": .string(error.localizedDescription)
            ]
        }
    }
    
    func handleFunctionCall(name: String, parameters: ProtobufStructContainer) async -> LiveSessionManager.Tools.ThinnedFunctionResponse {
        let response: Protobuf.Struct = switch name {
        case "discord_send_message":
            await handleSendMessageCall(parameters: parameters)
        default:
            [
                "error": .string("unknown function")
            ]
        }
        return .init(response: response)
    }
}
