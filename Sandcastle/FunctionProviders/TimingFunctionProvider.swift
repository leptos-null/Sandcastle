//
//  TimingFunctionProvider.swift
//  Sandcastle
//
//  Created by Leptos on 3/21/26.
//

import Foundation
import Gemini

class TimingFunctionProvider: LiveSessionManager.Tools.FunctionProvider {
    let functionDeclarations: [FunctionDeclaration] = [
        .init(
            name: "timing_sleep", description: "This function takes a specified number of seconds to complete. It has no other side effects.",
            behavior: nil, parameters: .object(properties: [
                "seconds": .number(minimum: 0.0),
            ]), parametersJsonSchema: nil, response: nil, responseJsonSchema: nil
        )
    ]
    
    init() {
    }
    
    private func handleSleepCall(parameters: Protobuf.Struct) async -> Protobuf.Struct {
        guard let secondsValue = parameters["seconds"] else {
            return [
                "error": .string("missing 'seconds' parameter")
            ]
        }
        guard case .number(let seconds) = secondsValue else {
            return [
                "error": .string("unsupported 'seconds' value")
            ]
        }
        
        do {
            try await Task.sleep(for: .seconds(seconds))
            
            return [
                "status": .string("success")
            ]
        } catch {
            return [
                "error": .string(error.localizedDescription)
            ]
        }
    }
    
    func handleFunctionCall(name: String, parameters: Protobuf.Struct) async -> LiveSessionManager.Tools.ThinnedFunctionResponse {
        let response: Protobuf.Struct = switch name {
        case "timing_sleep":
            await handleSleepCall(parameters: parameters)
        default:
            [
                "error": .string("unknown function")
            ]
        }
        return .init(response: response)
    }
}
