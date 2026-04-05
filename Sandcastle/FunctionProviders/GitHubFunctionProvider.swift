//
//  GitHubFunctionProvider.swift
//  Sandcastle
//
//  Created by Leptos on 3/21/26.
//

import Foundation
import Gemini

class GitHubFunctionProvider: LiveSessionManager.Tools.FunctionProvider {
    private let urlSession: URLSession
    
    let functionDeclarations: [FunctionDeclaration] = [
        .init(
            name: "github_arbitrary_api", description: "Fetch from an arbitrary GitHub REST API endpoint",
            behavior: nil, parameters: .object(properties: [
                "endpoint": .string(description: "A URL. This generally starts with `https://api.github.com`"),
            ]), parametersJsonSchema: nil, response: nil, responseJsonSchema: nil
        ),
        .init(
            name: "github_user_name", description: "Resolve the GitHub user name of the current user",
            behavior: nil, parameters: nil, parametersJsonSchema: nil, response: .object(properties: [
                "user_name": .string()
            ]), responseJsonSchema: nil
        ),
    ]
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    private func handleArbitraryApiCall(parameters: ProtobufStructContainer) async -> Protobuf.Struct {
        do {
            let endpoint: String = try parameters.value(for: "endpoint").string()
            
            guard let url = URL(string: endpoint) else {
                return [
                    "error": .string("unsupported 'endpoint' value")
                ]
            }
            
            let (responsePayload, urlResponse) = try await urlSession.data(from: url)
            
            let decoder = JSONDecoder()
            let jsonResponse = try decoder.decode(Protobuf.Value.self, from: responsePayload)
            
            var build: [String: Protobuf.Value] = [
                "payload": jsonResponse,
            ]
            
            if let httpResponse = urlResponse as? HTTPURLResponse {
                let relevantHeaderFields: [String] = [
                    "last-modified",
                    "x-ratelimit-limit",
                    "x-ratelimit-remaining",
                    "x-ratelimit-used",
                    "x-ratelimit-reset",
                ]
                
                let relevantHeaders: [String: Protobuf.Value] = relevantHeaderFields.reduce(into: [:]) { partialResult, headerField in
                    if let value = httpResponse.value(forHTTPHeaderField: headerField) {
                        partialResult[headerField] = .string(value)
                    }
                }
                
                build["metadata"] = .dictionary(relevantHeaders)
            }
            
            return build
        } catch {
            return [
                "error": .string(error.localizedDescription)
            ]
        }
    }
    
    func handleFunctionCall(name: String, parameters: ProtobufStructContainer) async -> LiveSessionManager.Tools.ThinnedFunctionResponse {
        let response: Protobuf.Struct = switch name {
        case "github_arbitrary_api":
            await handleArbitraryApiCall(parameters: parameters)
        case "github_user_name":
            [
                "user_name": .string(Config.githubUserName)
            ]
        default:
            [
                "error": .string("unknown function")
            ]
        }
        return .init(response: response)
    }
}
