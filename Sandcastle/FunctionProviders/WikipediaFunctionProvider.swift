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
    
    private let urlBase: String = "https://en.wikipedia.org/w/rest.php"
    
    // https://en.wikipedia.org/w/index.php?api=mw-extra&title=Special%3ARestSandbox
    
    let functionDeclarations: [FunctionDeclaration] = [
        .init(
            name: "wikipedia_search_page", description: "Lists pages matching the given search terms",
            behavior: nil, parameters: .object(properties: [
                "terms": .string(),
                "limit": .number(description: "Maximum number of search results to return. Defaults to 15", nullable: true, minimum: 1, maximum: 100)
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
            name: "wikipedia_page_raw", description: "Returns information about a page, including the page source, usually in wikitext.",
            behavior: nil, parameters: .object(properties: [
                "title": .string(description: "Page title in reading-friendly format"),
            ]), parametersJsonSchema: nil, response: nil, responseJsonSchema: nil
        )
    ]
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    private func handleSearchPageCall(parameters: Protobuf.Struct) async -> Protobuf.Struct {
        guard let termsValue = parameters["terms"] else {
            return [
                "error": .string("missing 'terms' parameter")
            ]
        }
        guard case .string(let terms) = termsValue else {
            return [
                "error": .string("unsupported 'terms' value")
            ]
        }
        
        let limit: Int
        
        if let limitValue = parameters["limit"] {
            guard case .number(let floatingLimit) = limitValue else {
                return [
                    "error": .string("unsupported 'limit' value")
                ]
            }
            // we don't need to check the bounds, because presumably, Wikipedia API will do that
            limit = Int(floatingLimit)
        } else {
            limit = 15
        }
        do {
            guard var urlComponents = URLComponents(string: urlBase + "/v1/search/page") else {
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
            let decodedResponse = try decoder.decode(WikipediaSearchPageResult.self, from: responsePayload)
            
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
    
    private func handlePageRawCall(parameters: Protobuf.Struct) async -> Protobuf.Struct {
        guard let titleValue = parameters["title"] else {
            return [
                "error": .string("missing 'title' parameter")
            ]
        }
        guard case .string(let title) = titleValue else {
            return [
                "error": .string("unsupported 'title' value")
            ]
        }
        
        do {
            // note: depends on iOS 17+ parsing behavior
            guard let url = URL(string: urlBase + "/v1/page/" + title) else {
                throw URLError(.badURL)
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.setValue("application/json", forHTTPHeaderField: "accept")
            
            let (responsePayload, _) = try await self.urlSession.data(for: urlRequest)
            
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
        case "wikipedia_search_page":
            await handleSearchPageCall(parameters: parameters)
        case "wikipedia_page_raw":
            await handlePageRawCall(parameters: parameters)
        default:
            [
                "error": .string("unknown function")
            ]
        }
        return .init(response: response)
    }
}

private struct WikipediaSearchPageResult: Decodable {
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
