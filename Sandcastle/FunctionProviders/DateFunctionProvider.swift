//
//  DateFunctionProvider.swift
//  Sandcastle
//
//  Created by Leptos on 3/29/26.
//

import Foundation
import Gemini

class DateFunctionProvider: LiveSessionManager.Tools.FunctionProvider {
    let functionDeclarations: [FunctionDeclaration] = [
        .init(
            name: "date_timezone", description: "Determine the user's local timezone",
            behavior: nil, parameters: nil, parametersJsonSchema: nil, response: .object(properties: [
                "identifier": .string(description: "The geopolitical region identifier that identifies the time zone", example: "America/Los_Angeles")
            ]), responseJsonSchema: nil
        ),
    ]
    
    init() {
    }
    
    private func handleTimezoneCall(parameters: Protobuf.Struct) -> Protobuf.Struct {
        let timezone: TimeZone = .current
        return [
            "identifier": .string(timezone.identifier)
        ]
    }
    
    func handleFunctionCall(name: String, parameters: Protobuf.Struct) async -> LiveSessionManager.Tools.ThinnedFunctionResponse {
        let response: Protobuf.Struct = switch name {
        case "date_timezone":
            handleTimezoneCall(parameters: parameters)
        default:
            [
                "error": .string("unknown function")
            ]
        }
        return .init(response: response)
    }
}
