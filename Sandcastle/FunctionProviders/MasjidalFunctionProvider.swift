//
//  MasjidalFunctionProvider.swift
//  Sandcastle
//
//  Created by Leptos on 3/29/26.
//

import Foundation
import Gemini

class MasjidalFunctionProvider: LiveSessionManager.Tools.FunctionProvider {
    private let urlSession: URLSession
    
    private let urlBase: String = "https://masjidal.com/api"
    
    let functionDeclarations: [FunctionDeclaration] = [
        .init(
            name: "masjidal_time_range",
            description: "Get prayer times for a given masjid. Unless otherwise specified all dates and times are local to the masjid.",
            behavior: nil, parameters: .object(properties: [
                "masjid_name": .string(
                    format: "enum",
                    enum: Array(Config.masjidEntries.keys)
                ),
                "from_date": .string(format: "date", description: "Start of the date range, inclusive. Defaults to today", nullable: true),
                "to_date": .string(format: "date", description: "End of the date range, inclusive. Defaults to today", nullable: true),
            ]), parametersJsonSchema: nil, response: .anyOf(schemas: [
                .object(properties: [
                    "status": .string(),
                    "data": .object(properties: [
                        "salah": .array(items: .object(properties: [
                            "date": .string(example: "Monday, Mar 30, 2026"),
                            "day": .string(description: "Day of the week"),
                            "hijri_date": .string(description: "Hijri day and year", example: "11, 1447"),
                            "hijri_month": .string(description: "Hijri month name"),
                            
                            "fajr": .string(),
                            "sunrise": .string(),
                            "zuhr": .string(),
                            "asr": .string(),
                            "maghrib": .string(),
                            "isha": .string(),
                        ])),
                        "iqamah": .array(items: .object(properties: [
                            "date": .string(example: "Monday, Mar 30, 2026"),
                            
                            "fajr": .string(),
                            "zuhr": .string(),
                            "asr": .string(),
                            "maghrib": .string(),
                            "isha": .string(),
                            
                            "jummah1": .string(nullable: true),
                            "jummah2": .string(nullable: true),
                        ])),
                    ]),
                ]),
                .object(properties: [
                    "error": .string()
                ]),
            ]), responseJsonSchema: nil
        ),
    ]
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    private func handleTimeRangeCall(parameters: Protobuf.Struct) async -> Protobuf.Struct {
        guard let masjidNameValue = parameters["masjid_name"] else {
            return [
                "error": .string("missing 'masjid_name' parameter")
            ]
        }
        guard case .string(let masjidName) = masjidNameValue,
              let masjidID = Config.masjidEntries[masjidName] else {
            return [
                "error": .string("unsupported 'masjid_name' value")
            ]
        }
        
        // thanks to
        // <https://github.com/siddiki8/masjidal-salah-api/blob/c78879a3ab0b8c5243d41af6f6cfddee870a9013/src/worker.py#L81>
        
        do {
            guard var urlComponents = URLComponents(string: urlBase + "/v1/time/range") else {
                throw URLError(.badURL)
            }
            
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "masjid_id", value: masjidID),
            ]
            if case .string(let fromDate) = parameters["from_date"] {
                queryItems.append(URLQueryItem(name: "from_date", value: fromDate))
            }
            if case .string(let toDate) = parameters["to_date"] {
                queryItems.append(URLQueryItem(name: "to_date", value: toDate))
            }
            urlComponents.queryItems = queryItems
            
            guard let url = urlComponents.url else {
                throw URLError(.badURL)
            }
            
            let (responsePayload, _) = try await urlSession.data(from: url)
            
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(Protobuf.Struct.self, from: responsePayload)
            
            return decodedResponse
        } catch {
            return [
                "error": .string(error.localizedDescription)
            ]
        }
    }
    
    func handleFunctionCall(name: String, parameters: Protobuf.Struct) async -> LiveSessionManager.Tools.ThinnedFunctionResponse {
        let response: Protobuf.Struct = switch name {
        case "masjidal_time_range":
            await handleTimeRangeCall(parameters: parameters)
        default:
            [
                "error": .string("unknown function")
            ]
        }
        return .init(response: response)
    }
}
