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
                "masjid_id": .string(description: "An opaque identifier"),
                "from_date": .string(format: "date", description: "Start of the date range, inclusive. Defaults to today", nullable: true),
                "to_date": .string(format: "date", description: "End of the date range, inclusive. Defaults to today", nullable: true),
            ]), parametersJsonSchema: nil, response: .anyOf(schemas: [
                .object(properties: [
                    "status": .string(),
                    "data": .object(properties: [
                        "salah": .array(items: .object(description: "The time when each prayer comes in", properties: [
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
                        "iqamah": .array(items: .object(description: "The times members pray together at the masjid", properties: [
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
        .init(
            name: "masjidal_masjids_proximity",
            description: "Find masjids near a given coordinate",
            behavior: nil, parameters: .object(properties: [
                "latitude": .number(minimum: -90, maximum: +90),
                "longitude": .number(minimum: -180, maximum: +180),
                // one might think distance should be a number (i.e. floating point), however in testing, the API only accepts integers
                "distance": .integer(description: "The radius in miles to search. Defaults to 5", nullable: true, minimum: 1),
                "page": .integer(description: "Page number of the results. Defaults to 1", nullable: true),
            ]), parametersJsonSchema: nil, response: .anyOf(schemas: [
                .object(properties: [
                    "_meta": .object(properties: [
                        "currentPage": .integer(),
                        "pageCount": .integer(),
                        "perPage": .integer(),
                        "totalCount": .integer(),
                    ]),
                    "items": .array(
                        items: .object(properties: [
                            "id": .string(description: "Suitable for passing to masjid_id"),
                            "name": .string(),
                            "website_url": .string(),
                            "distance": .string(description: "Distance from the query coordinate in miles"),
                            
                            "address": .string(),
                            "city": .string(),
                            "zipcode": .string(),
                            "state": .string(),
                            "country": .string(),
                            
                            "latitude": .string(),
                            "longitude": .string(),
                        ])
                    ),
                ]),
                .object(properties: [
                    "error": .string()
                ]),
            ]), responseJsonSchema: nil
        ),
        .init(
            name: "masjidal_masjid_name_to_id",
            description: "Resolve a masjid name to its ID",
            behavior: nil, parameters: .object(properties: [
                "name": .string(
                    format: "enum",
                    enum: Array(Config.masjidEntries.keys)
                ),
            ]), parametersJsonSchema: nil, response: .anyOf(schemas: [
                .object(properties: [
                    "id": .string(description: "Suitable for passing to masjid_id"),
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
    
    private func handleTimeRangeCall(parameters: ProtobufStructContainer) async -> Protobuf.Struct {
        // thanks to
        // <https://github.com/siddiki8/masjidal-salah-api/blob/c78879a3ab0b8c5243d41af6f6cfddee870a9013/src/worker.py#L81>
        
        do {
            let masjidId: String = try parameters.value(for: "masjid_id").string()
            let fromDate: String? = try parameters.value(for: "from_date").accessIfPresent { try $0.string() }
            let toDate: String? = try parameters.value(for: "to_date").accessIfPresent { try $0.string() }
            
            guard var urlComponents = URLComponents(string: urlBase + "/v1/time/range") else {
                throw URLError(.badURL)
            }
            
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "masjid_id", value: masjidId),
            ]
            if let fromDate {
                queryItems.append(URLQueryItem(name: "from_date", value: fromDate))
            }
            if let toDate {
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
    
    private func handleMasjidsProximityCall(parameters: ProtobufStructContainer) async -> Protobuf.Struct {
        do {
            let latitude: Double = try parameters.value(for: "latitude").double()
            let longitude: Double = try parameters.value(for: "longitude").double()
            let distance: Double? = try parameters.value(for: "distance").accessIfPresent { try $0.double() }
            let page: Double? = try parameters.value(for: "page").accessIfPresent { try $0.double() }
            
            guard var urlComponents = URLComponents(string: urlBase + "/v3/masjids/proximity") else {
                throw URLError(.badURL)
            }
            
            let posixLocale: Locale = .init(identifier: "en_US_POSIX")
            let coordinateComponentStyle: FloatingPointFormatStyle<Double> = .init(locale: posixLocale)
                .precision(.fractionLength(1...6))
            
            let fixedPointStyle: FloatingPointFormatStyle<Double> = .init(locale: posixLocale)
                .precision(.fractionLength(0))
            
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "lat", value: latitude.formatted(coordinateComponentStyle)),
                URLQueryItem(name: "long", value: longitude.formatted(coordinateComponentStyle)),
            ]
            if let distance {
                queryItems.append(URLQueryItem(name: "distance", value: distance.formatted(fixedPointStyle)))
            }
            if let page {
                queryItems.append(URLQueryItem(name: "page", value: page.formatted(fixedPointStyle)))
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
    
    private func handleMasjidNameToId(parameters: ProtobufStructContainer) async -> Protobuf.Struct {
        let name: String
        do {
            name = try parameters.value(for: "name").string()
        } catch {
            return [
                "error": .string(error.localizedDescription)
            ]
        }
        guard let masjidID = Config.masjidEntries[name] else {
            return [
                "error": .string("unsupported 'name' value")
            ]
        }
        return [
            "id": .string(masjidID)
        ]
    }
    
    func handleFunctionCall(name: String, parameters: ProtobufStructContainer) async -> LiveSessionManager.Tools.ThinnedFunctionResponse {
        let response: Protobuf.Struct = switch name {
        case "masjidal_time_range":
            await handleTimeRangeCall(parameters: parameters)
        case "masjidal_masjids_proximity":
            await handleMasjidsProximityCall(parameters: parameters)
        case "masjidal_masjid_name_to_id":
            await handleMasjidNameToId(parameters: parameters)
        default:
            [
                "error": .string("unknown function")
            ]
        }
        return .init(response: response)
    }
}
