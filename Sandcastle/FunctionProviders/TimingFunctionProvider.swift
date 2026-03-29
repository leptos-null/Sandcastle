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
        ),
        .init(
            name: "timing_callback", description: "This function asynchronously completes after a specified number of seconds. It has no other side effects.",
            behavior: .nonBlocking, parameters: .object(properties: [
                "seconds": .number(minimum: 0.0),
                "scheduling": .string(format: "enum", description: "Specifies how the response should be scheduled in the conversation", enum: [
                    FunctionResponse.Scheduling.whenIdle.rawValue,
                    FunctionResponse.Scheduling.interrupt.rawValue
                ])
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
    
    private func handleCallbackCall(parameters: Protobuf.Struct) async -> LiveSessionManager.Tools.ThinnedFunctionResponse {
        guard let secondsValue = parameters["seconds"] else {
            return .init(response: [
                "error": .string("missing 'seconds' parameter")
            ])
        }
        guard case .number(let seconds) = secondsValue else {
            return .init(response: [
                "error": .string("unsupported 'seconds' value")
            ])
        }
        
        guard let schedulingValue = parameters["scheduling"] else {
            return .init(response: [
                "error": .string("missing 'scheduling' parameter")
            ])
        }
        guard case .string(let rawScheduling) = schedulingValue,
              let scheduling = FunctionResponse.Scheduling(rawValue: rawScheduling) else {
            return .init(response: [
                "error": .string("unsupported 'scheduling' value")
            ])
        }
        
        do {
            try await Task.sleep(for: .seconds(seconds))
            
            return .init(response: [
                "status": .string("success")
            ], willContinue: false, scheduling: scheduling)
        } catch {
            return .init(response: [
                "error": .string(error.localizedDescription)
            ])
        }
    }
    
    func handleFunctionCall(name: String, parameters: Protobuf.Struct) async -> LiveSessionManager.Tools.ThinnedFunctionResponse {
        switch name {
        case "timing_sleep":
            let response: Protobuf.Struct = await handleSleepCall(parameters: parameters)
            return .init(response: response)
        case "timing_callback":
            return await handleCallbackCall(parameters: parameters)
        default:
            return .init(response: [
                "error": .string("unknown function")
            ])
        }
    }
}
