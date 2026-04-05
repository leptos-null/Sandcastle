//
//  WikipediaFunctionProvider.swift
//  Sandcastle
//
//  Created by Leptos on 3/29/26.
//

import Foundation
import Gemini

class WikipediaFunctionProvider: LiveSessionManager.Tools.FunctionProvider {
    private let urlSession: URLSession
    
    let functionDeclarations: [FunctionDeclaration] = [
        .init(
            name: "wikipedia_search_page", description: "Lists pages matching the given search terms",
            behavior: nil, parameters: .object(properties: [
                "terms": .string(),
                "limit": .integer(description: "Maximum number of search results to return. Defaults to 15", nullable: true, minimum: 1, maximum: 100)
            ]), parametersJsonSchema: nil, response: .anyOf(schemas: [
                .object(properties: [
                    "pages": .array(items: .object(properties: [
                        "key": .string(description: "Page title in URL-friendly format"),
                        "title": .string(description: "Page title in reading-friendly format"),
                        "excerpt": .string(description: "Excerpt of the page content matching the search query", nullable: true),
                        "matched_title": .string(description: "Title of the page redirected from, if the search term matched a redirect page, or else null", nullable: true),
                        "description": .string(description: "Short summary of the page topic or null if no summary exists", nullable: true)
                    ]))
                ]),
                .object(properties: [
                    "error": .string()
                ])
            ]), responseJsonSchema: nil
        ),
        .init(
            name: "wikipedia_page_summary", description: "Returns a summary of a page",
            behavior: nil, parameters: .object(properties: [
                "title": .string(description: "Page title in URL-friendly format"),
            ]), parametersJsonSchema: nil, response: .anyOf(schemas: [
                .object(properties: [
                    "page_id": .number(nullable: true),
                    "extract": .string(description: "First several sentences of the article in plain text"),
                    "language": .string(),
                    "last_edit_time": .string(description: "The time when the page was last edited, in the ISO 8601 format", nullable: true),
                    "description": .string(description: "Wikidata description for the page", nullable: true),
                    "coordinates": .object(nullable: true, properties: [
                        "latitude": .number(),
                        "longitude": .number(),
                    ]),
                ]),
                .object(properties: [
                    "error": .string()
                ])
            ]), responseJsonSchema: nil
        )
    ]
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    // https://en.wikipedia.org/w/index.php?api=mw-extra&title=Special%3ARestSandbox#/default/get_v1_search_page
    private func handleSearchPageCall(parameters: ProtobufStructContainer) async -> Protobuf.Struct {
        do {
            let terms: String = try parameters.value(for: "terms").string()
            // we don't need to check the bounds, because presumably, Wikipedia API will do that
            let limit: Int = try parameters.value(for: "limit").accessIfPresent { try $0.integer() } ?? 15
            
            guard var urlComponents = URLComponents(string: "https://en.wikipedia.org/w/rest.php/v1/search/page") else {
                throw URLError(.badURL)
            }
            urlComponents.queryItems = [
                URLQueryItem(name: "q", value: terms),
                URLQueryItem(name: "limit", value: String(limit)),
            ]
            guard let url = urlComponents.url else {
                throw URLError(.badURL)
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.setValue("application/json", forHTTPHeaderField: "accept")
            
            let (responsePayload, _) = try await self.urlSession.data(for: urlRequest)
            
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(WikipediaSearchPageResponse.self, from: responsePayload)
            
            let pageValues: [Protobuf.Value] = decodedResponse.pages.map { page in
                var build: [String: Protobuf.Value] = [
                    "key": .string(page.key),
                    "title": .string(page.title),
                ]
                
                if let excerpt = page.excerpt {
                    build["excerpt"] = .string(excerpt)
                }
                if let matchedTitle = page.matchedTitle {
                    build["matched_title"] = .string(matchedTitle)
                }
                if let description = page.description {
                    build["description"] = .string(description)
                }
                
                return .dictionary(build)
            }
            
            return [
                "pages": .array(pageValues)
            ]
        } catch {
            return [
                "error": .string(error.localizedDescription)
            ]
        }
    }
    
    // https://en.wikipedia.org/w/index.php?api=wmf-restbase&title=Special%3ARestSandbox#/Page%20content/get_page_summary__title_
    private func handlePageSummaryCall(parameters: ProtobufStructContainer) async -> Protobuf.Struct {
        do {
            let title: String = try parameters.value(for: "title").string()
            
            guard let baseURL = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary") else {
                throw URLError(.badURL)
            }
            
            let url = baseURL.appending(component: title)
            
            var urlRequest = URLRequest(url: url)
            urlRequest.setValue("application/json; charset=utf-8; profile=\"https://www.mediawiki.org/wiki/Specs/Summary/1.4.2\"", forHTTPHeaderField: "accept")
            // per the documentation
            urlRequest.addValue("https://github.com/leptos-null/Sandcastle", forHTTPHeaderField: "Api-User-Agent")
            
            let (responsePayload, _) = try await self.urlSession.data(for: urlRequest)
            
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(WikipediaPageSummaryResponse.self, from: responsePayload)
            
            var build: Protobuf.Struct = [
                "extract": .string(decodedResponse.extract),
                "language": .string(decodedResponse.lang),
            ]
            if let pageID = decodedResponse.pageid {
                build["page_id"] = .number(Double(pageID))
            }
            if let timestamp = decodedResponse.timestamp {
                build["last_edit_time"] = .string(timestamp)
            }
            if let description = decodedResponse.description {
                build["description"] = .string(description)
            }
            if let coordinates = decodedResponse.coordinates {
                build["coordinates"] = [
                    "latitude": .number(coordinates.lat),
                    "longitude": .number(coordinates.lon),
                ]
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
        case "wikipedia_search_page":
            await handleSearchPageCall(parameters: parameters)
        case "wikipedia_page_summary":
            await handlePageSummaryCall(parameters: parameters)
        default:
            [
                "error": .string("unknown function")
            ]
        }
        return .init(response: response)
    }
}

private struct WikipediaSearchPageResponse: Decodable {
    struct Entry: Decodable {
        enum CodingKeys: String, CodingKey {
            case id
            case key
            case title
            case excerpt
            case matchedTitle = "matched_title"
            case description
        }
        
        /// Page identifier
        let id: Int
        /// Page title in URL-friendly format
        let key: String
        /// Page title in reading-friendly format
        let title: String
        
        /// Excerpt of the page content matching the search query
        let excerpt: String?
        /// Title of the page redirected from, if the search term matched a redirect page, or else null
        let matchedTitle: String?
        /// Short summary of the page topic or null if no summary exists
        let description: String?
    }
    
    let pages: [Entry]
}

private struct WikipediaPageSummaryResponse: Decodable {
    struct TitlesSet: Decodable {
        /// the DB key (non-prefixed)
        let canonical: String
        /// the normalized title
        let normalized: String
        /// the title as it should be displayed to the user
        let display: String
    }
    
    struct Coordinates: Decodable {
        /// The latitude
        let lat: Double
        /// The longitude
        let lon: Double
    }
    
    let titles: TitlesSet
    /// The page ID
    let pageid: Int?
    /// First several sentences of an article in plain text
    let extract: String
    /// The page language code
    let lang: String
    /// The page language direction code
    let dir: String
    /// The time when the page was last edited in the [ISO 8601](<https://en.wikipedia.org/wiki/ISO_8601>) format
    let timestamp: String?
    /// Wikidata description for the page
    let description: String?
    /// The coordinates of the item
    let coordinates: Coordinates?
}
