//
//  BidiGenerateContentSession.swift
//  Sandcastle
//
//  Created by Leptos on 2/21/26.
//

import Foundation
import Gemini
import OSLog

final actor BidiGenerateContentSession {
    private let urlSession: URLSession
    
    private static let logger = Logger(subsystem: "BidiGenerateContent", category: "Session")
    
    private let encoder: JSONEncoder = .init()
    private let decoder: JSONDecoder = .init()
    
    private var webSocketTask: URLSessionWebSocketTask?
    
    private let webSocketDelegate = BidiWebSocketDelegate(logger: logger)
    
    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    init() {
        let sessionConfiguration: URLSessionConfiguration = .default
        let urlSession = URLSession(configuration: sessionConfiguration)
        
        self.init(urlSession: urlSession)
    }
    
    var isConnected: Bool {
        webSocketTask != nil
    }
    
    func connect(request: URLRequest) throws -> AsyncThrowingStream<BidiGenerateContentServerMessage, Swift.Error> {
        if isConnected {
            throw POSIXError(.EISCONN)
        }
        
        let task = urlSession.webSocketTask(with: request)
        task.delegate = webSocketDelegate
        
        webSocketTask = task
        task.resume()
        
        let (asyncStream, streamContinuation) = AsyncThrowingStream.makeStream(of: BidiGenerateContentServerMessage.self)
        // technically this Task is leaked, however when this object (`self`) gets `deinit`,
        // we cancel the web socket, which should end the loop, and exit this Task
        Task<Void, Never> { [weak self] in
            do {
                while task.state != .completed, let self {
                    let message = try await self.receiveMessage(from: task)
                    streamContinuation.yield(message)
                }
                streamContinuation.finish()
            } catch {
                streamContinuation.finish(throwing: error)
            }
            guard let self else { return }
            await self.clearWebSocketTaskIfMatches(task)
        }
        return asyncStream
    }
    
    private func clearWebSocketTaskIfMatches(_ task: URLSessionWebSocketTask) {
        if self.webSocketTask === task {
            self.webSocketTask = nil
        }
    }
    
    func send(message: BidiGenerateContentClientMessage) async throws {
        guard let webSocketTask else {
            throw POSIXError(.ENOTCONN)
        }
        let rawMessage = try encoder.encode(message)
        let stringyMessage = String(decoding: rawMessage, as: UTF8.self)
        
        let shouldLog: Bool = if case .realtimeInput(let realtimeInput) = message,
                                 realtimeInput.activityStart == nil, realtimeInput.activityEnd == nil,
                                 realtimeInput.audioStreamEnd == nil,
                                 realtimeInput.text == nil {
            false // these are incredibly noisy, and there probably isn't very much to learn from these logs
        } else {
            true
        }
        if shouldLog {
            Self.logger.debug("send: \(self.processMessageForLogging(rawMessage))")
        }
        
        try await webSocketTask.send(.string(stringyMessage))
    }
    
    private func receiveMessage(from task: URLSessionWebSocketTask) async throws -> BidiGenerateContentServerMessage {
        let message = try await task.receive()
        
        let encodedMessage: Data
        switch message {
        case .data(let data):
            encodedMessage = data
        case .string(let string):
            encodedMessage = Data(string.utf8)
        @unknown default:
            throw WebSocketError.unknownMessageType
        }
        Self.logger.debug("recv: \(self.processMessageForLogging(encodedMessage))")
        
        let decodedMessage = try decoder.decode(BidiGenerateContentServerMessage.self, from: encodedMessage)
        return decodedMessage
    }
    
    private static func processValueForLogging(_ json: Protobuf.Value) -> Protobuf.Value {
        switch json {
        case .string(let string):
            let stringCount: Int = string.count
            // randomly selected
            if stringCount > 512 {
                return .string("[truncated] \(stringCount) characters")
            }
            return json
        case .array(let array):
            return .array(array.map(processValueForLogging))
        case .dictionary(let dictionary):
            return .dictionary(dictionary.mapValues(processValueForLogging))
        case .number, .bool, .null:
            return json
        }
    }
    
    private func processMessageForLogging(_ encodedMessage: Data) -> String {
        do {
            let decoded = try decoder.decode(Protobuf.Value.self, from: encodedMessage)
            let processed = Self.processValueForLogging(decoded)
            
            let encoded = try encoder.encode(processed)
            return "[json] " + String(decoding: encoded, as: UTF8.self)
        } catch {
            if let string = String(data: encodedMessage, encoding: .utf8) {
                return "[utf8] " + string
            }
            return "[binary] " + encodedMessage.description
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
    
    deinit {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}

extension BidiGenerateContentSession {
    enum WebSocketError: Swift.Error {
        /// Unknown `URLSessionWebSocketTask.Message` case
        case unknownMessageType
    }
}

extension BidiGenerateContentSession {
    // for development convenience - API keys should not be used on-device in production
    //
    // at the time of writing, `BidiGenerateContent` requires `InterfaceVersion.v1beta` or `InterfaceVersion.v1alpha`
    nonisolated static func requestFor(apiKey: String, apiVersion: InterfaceVersion) throws -> URLRequest {
        // https://ai.google.dev/api/live#websocket-connection
        guard let url = URL(string: "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.\(apiVersion.rawValue).GenerativeService.BidiGenerateContent") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        // https://ai.google.dev/api#authentication
        request.addValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        
        return request
    }
    
    // at the time of writing, accessToken authentication is only supported on `InterfaceVersion.v1alpha`
    nonisolated static func requestFor(accessToken: String, apiVersion: InterfaceVersion) throws -> URLRequest {
        // https://ai.google.dev/api/live#ephemeral-auth-tokens
        guard let url = URL(string: "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.\(apiVersion.rawValue).GenerativeService.BidiGenerateContentConstrained") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.addValue("Token \(accessToken)", forHTTPHeaderField: "Authorization")
        
        return request
    }
}

// (currently) only for debugging/ observability
private class BidiWebSocketDelegate: NSObject, URLSessionWebSocketDelegate {
    let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocl: String?) {
        logger.trace("urlSession(_, webSocketTask: _, didOpenWithProtocol: \(protocl ?? "<nil>"))")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reasonDescription: String
        if let reason {
            if let string = String(data: reason, encoding: .utf8) {
                reasonDescription = "[utf8] " + string
            } else {
                reasonDescription = reason.description
            }
        } else {
            reasonDescription = "<nil>"
        }
        
        logger.trace("urlSession(_, webSocketTask: _, didCloseWith: \(closeCode.rawValue), reason: \(reasonDescription))")
    }
}
