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
    
    private func handleSleepCall(parameters: ProtobufStructContainer) async -> Protobuf.Struct {
        do {
            let seconds: Double = try parameters.value(for: "seconds").double()
            
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
    
    private func handleCallbackCall(parameters: ProtobufStructContainer) async -> LiveSessionManager.Tools.ThinnedFunctionResponse {
        do {
            let seconds: Double = try parameters.value(for: "seconds").double()
            let scheduling: FunctionResponse.Scheduling = try parameters.value(for: "scheduling").rawRepresentable()
            
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
    
    func handleFunctionCall(name: String, parameters: ProtobufStructContainer) async -> LiveSessionManager.Tools.ThinnedFunctionResponse {
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
