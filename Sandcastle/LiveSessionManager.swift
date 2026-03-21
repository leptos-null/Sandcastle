//
//  LiveSessionManager.swift
//  Sandcastle
//
//  Created by Leptos on 2/21/26.
//

import Foundation
import AVFoundation
import Gemini
import OSLog

@MainActor
@Observable
final class LiveSessionManager {
    private enum State {
        case idle
        case connecting
        case connected
        case setup
        
        case terminated
    }
    
    private static let logger = Logger(subsystem: "LiveSessionManager", category: "Root")
    
    let bidiSession: BidiGenerateContentSession = .init()
    
    private var state: State = .idle
    private(set) var recentError: Swift.Error?
    
    let audio = Audio()
    let transcript = Transcript()
    let usage = Usage()
    let tools = Tools()
    let haptics = Haptics()
    let playground = Playground()
    
    init() {
        audio.manager = self
        tools.manager = self
    }
    
    func startIfNeeded() {
        guard case .idle = state else { return }
        
        recentError = nil
        state = .connecting
        
        Task<Void, Never> { [weak self] in
            do {
                let stream: AsyncThrowingStream<BidiGenerateContentServerMessage, Swift.Error>
                if let self { // not using `guard let` so that we don't continue holding a reference to `self` below
                    // TODO: using API key for development only
                    guard let cApiKey = getenv("GOOGLE_AI_API_KEY") else {
                        fatalError("Expected GOOGLE_AI_API_KEY environment variable")
                    }
                    let apiKey = String(cString: cApiKey)
                    let request = try BidiGenerateContentSession.requestFor(apiKey: apiKey, apiVersion: .v1alpha)
                    
                    stream = try await self.bidiSession.connect(request: request)
                    self.state = .connected
                    
                    try await self.setup()
                    
                    try audio.resume()
                } else {
                    return
                }
                
                for try await message in stream {
                    guard let self else { break }
                    if case .setupComplete = message.messageType {
                        self.state = .setup
                    }
                    self.audio.onServerMessage(message)
                    self.transcript.onServerMessage(message)
                    self.usage.onServerMessage(message)
                    self.tools.onServerMessage(message)
                }
            } catch {
                Self.logger.error("Connection error: \(error)")
                self?.recentError = error
            }
            self?.state = .terminated
        }
    }
    
    private func setup() async throws {
        guard case .connected = state else {
            throw StateError()
        }
        
        self.tools.onSetup()
        
        let tools: [Tool] = self.tools.functionProviders.map { provider in
            Tool(functionDeclarations: provider.functionDeclarations)
        }
        
        let setup: BidiGenerateContentSetup = .init(
            model: "models/gemini-2.5-flash-native-audio-preview-12-2025",
            generationConfig: .init(
                responseModalities: [ .audio ],
                enableAffectiveDialog: true,
                speechConfig: .init(voiceConfig: .init(value: .prebuiltVoiceConfig(.umbriel)))
            ),
            tools: tools,
            inputAudioTranscription: .init(),
            outputAudioTranscription: .init(),
            proactivity: .init(proactiveAudio: true)
        )
        try await self.bidiSession.send(message: .setup(setup))
        
        try audio.setupIfNeeded()
    }
}

extension LiveSessionManager {
    nonisolated struct StateError: Swift.Error {
    }
}


extension LiveSessionManager {
    @MainActor
    @Observable
    final class Audio {
        private nonisolated static let logger = Logger(subsystem: "LiveSessionManager", category: "Audio")
        
        private let audioEngine = AVAudioEngine()
        private let playerNode = AVAudioPlayerNode()
        
        // per <https://ai.google.dev/gemini-api/docs/live-guide#audio-formats>
        // and <https://ai.google.dev/gemini-api/docs/live?example=mic-stream#get-started>
        private let playFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 24_000,
            channels: 1,
            interleaved: false // since it's 1 channel, this value doesn't really matter
        )
        
        @ObservationIgnored
        fileprivate weak var manager: LiveSessionManager?
        
        var isMuted: Bool = false {
            didSet {
                guard isSetup else { return }
                audioEngine.inputNode.isVoiceProcessingInputMuted = isMuted
            }
        }
        
        @ObservationIgnored
        private var isSetup: Bool = false
        
        private var wantsRunning: Bool = false
        private(set) var isRunning: Bool = false
        
        @ObservationIgnored
        private var defaultNotificationCenterObservers: [NSObjectProtocol] = []
        
#if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        @ObservationIgnored
        private var pushedAudioSessionState: AVAudioSession.State?
#endif
        
        // input/ user/ microphone audio
        let inputAudioAnalyzer = SpectrumAnalyzer()
        // output/ model/ generated audio
        let outputAudioAnalyzer = SpectrumAnalyzer()
        
        func setupIfNeeded() throws {
            if isSetup { return }
            
            // because this code (currently) only runs once per `audioEngine` lifetime,
            // the code must not depend on the `audioEngine.inputNode` audio format, since that may change.
            // see the doc comment for `AVAudioEngineConfigurationChangeNotification` for more info.
            
            audioEngine.attach(playerNode)
            
            let inputNode = audioEngine.inputNode
            try inputNode.setVoiceProcessingEnabled(true)
            inputNode.isVoiceProcessingInputMuted = isMuted
            
            let mainMixerNode = audioEngine.mainMixerNode
            audioEngine.connect(playerNode, to: mainMixerNode, format: playFormat)
            audioEngine.connect(mainMixerNode, to: audioEngine.outputNode, format: nil)
            
            // per <https://ai.google.dev/gemini-api/docs/live-guide#audio-formats>
            guard let targetListenFormat = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: 16_000,
                channels: 1,
                interleaved: false // since it's 1 channel, this value doesn't really matter
            ) else {
                throw AVError(.formatUnsupported)
            }
            let microphoneBufferConverter = AudioBufferConverter()
            
            // (per link above) the Gemini Live API doesn't _require_ we provide 16kHz audio, however it is preferred.
            // because of this, we could avoid using an `AudioBufferConverter` by adding a Mixer node to the input,
            // which can convert between "common" formats (e.g. convert into `.pcmFormatInt16`) but cannot convert between
            // sample rates (I'm not sure about channel count conversions, but I'm guessing not).
            // however, since the input format could change (see comment above), we would need to re-configure the mixer node,
            // which would include re-setting up the tap below. Because of these trade-offs, I decided to use the audio converter
            // so we wouldn't have to manage re-configuring the mixer node, and we can pretty easily send the audio in the preferred format.
            
            let posixLocale = Locale(identifier: "en_US_POSIX")
            let mimeSampleRateFormat: FloatingPointFormatStyle<Double> = .init(locale: posixLocale)
                .grouping(.never)
                .rounded(rule: .toNearestOrEven, increment: 1)
                .precision(.fractionLength(0))
            
            // no particular reason for this buffer size
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                Task<Void, Never> {
                    let targetBuffer: AVAudioPCMBuffer
                    do {
                        targetBuffer = try await microphoneBufferConverter.convert(buffer: buffer, to: targetListenFormat)
                    } catch {
                        Self.logger.error("convert(buffer:to:) -> \(error)")
                        return
                    }
                    
                    guard let self, let manager = self.manager else { return }
                    
                    guard let audioChannelData = targetBuffer.int16ChannelData else {
                        Self.logger.error("Missing int16ChannelData on listen buffer")
                        return
                    }
                    guard targetBuffer.format.channelCount == 1 else {
                        Self.logger.error("Only 1 channel supported for encoding audio buffer")
                        return
                    }
                    
                    self.inputAudioAnalyzer.append(buffer: targetBuffer)
                    
                    let bufferPointer = UnsafeBufferPointer(start: audioChannelData[0], count: Int(targetBuffer.frameLength))
                    let data = Data(buffer: bufferPointer)
                    
                    let formattedRate: String = targetBuffer.format.sampleRate.formatted(mimeSampleRateFormat)
                    
                    let input = BidiGenerateContentRealtimeInput(
                        audio: Blob(mimeType: "audio/pcm;rate=\(formattedRate)", data: data)
                    )
                    do {
                        try await manager.bidiSession.send(message: .realtimeInput(input))
                    } catch {
                        Self.logger.error("bidiSession.send(message: .realtimeInput) -> \(error)")
                    }
                }
            }
            
            // use a separate buffer converter instance since the converter caches based on input/output formats,
            // and the input formats are (very likely) different between the two taps
            let playerBufferConverter = AudioBufferConverter()
            mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                Task<Void, Never> {
                    let targetBuffer: AVAudioPCMBuffer
                    do {
                        targetBuffer = try await playerBufferConverter.convert(buffer: buffer, to: targetListenFormat)
                    } catch {
                        Self.logger.error("convert(buffer:to:) -> \(error)")
                        return
                    }
                    guard let self else { return }
                    self.outputAudioAnalyzer.append(buffer: targetBuffer)
                }
            }
            
            let notificationCenter: NotificationCenter = .default
            let notificationCenterObserver = notificationCenter.addObserver(forName: .AVAudioEngineConfigurationChange, object: audioEngine, queue: .main) { [weak self] notification in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    let audioEngine = self.audioEngine
                    
                    guard self.wantsRunning else { return }
                    if audioEngine.isRunning { return }
                    do {
                        try audioEngine.start()
                    } catch {
                        Self.logger.error("after AVAudioEngineConfigurationChange - audioEngine.start -> \(error)")
                    }
                }
            }
            defaultNotificationCenterObservers.append(notificationCenterObserver)
            
            isSetup = true
        }
        
        func onServerMessage(_ message: BidiGenerateContentServerMessage) {
            guard case .serverContent(let serverContent) = message.messageType else {
                return
            }
            
            if serverContent.interrupted == true {
                playerNode.stop()
            }
            
            guard let modelTurn = serverContent.modelTurn else {
                return
            }
            
            guard let playFormat else {
                Self.logger.error("playFormat not supported")
                return
            }
            
            for turn in modelTurn.parts {
                guard case .inlineData(let partBlob) = turn.data,
                      partBlob.mimeType == "audio/pcm;rate=24000" else {
                    continue
                }
                // pcmFormatInt16 -> 16 bits = 2 bytes
                let pcmDataCount = partBlob.data.count / 2
                guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: playFormat, frameCapacity: AVAudioFrameCount(pcmDataCount)) else {
                    Self.logger.error("Failed to create AVAudioPCMBuffer from modelTurn data")
                    continue
                }
                guard let audioChannelData = audioBuffer.int16ChannelData else {
                    Self.logger.error("Missing int16ChannelData on play buffer")
                    continue
                }
                audioBuffer.frameLength = AVAudioFrameCount(pcmDataCount)
                partBlob.data.withUnsafeBytes { (pcmRawBufferPointer: UnsafeRawBufferPointer) in
                    guard let pcmRawSrcPointer = pcmRawBufferPointer.baseAddress else { return }
                    let pcmTypedSrcPointer = pcmRawSrcPointer.assumingMemoryBound(to: Int16.self)
                    audioChannelData[0].initialize(from: pcmTypedSrcPointer, count: pcmDataCount)
                }
                
                if !playerNode.isPlaying {
                    playerNode.play()
                }
                
                playerNode.scheduleBuffer(audioBuffer, completionCallbackType: .dataConsumed, completionHandler: nil)
            }
        }
        
        func resume() throws {
            wantsRunning = true
#if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
            let audioSession: AVAudioSession = .sharedInstance()
            
            pushedAudioSessionState = audioSession.state
            
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.bluetoothHighQualityRecording, .allowBluetoothHFP, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
#endif
            try audioEngine.start()
            
            isRunning = true
        }
        
        func pause() {
            wantsRunning = false
            audioEngine.stop()
            isRunning = false
            
#if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
            if let pushedAudioSessionState {
                let audioSession: AVAudioSession = .sharedInstance()
                do {
                    try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                    try audioSession.setState(pushedAudioSessionState)
                } catch {
                    Self.logger.error("audioSession.setState -> \(error)")
                }
                self.pushedAudioSessionState = nil
            }
#endif
        }
        
        deinit {
            // self is isolated (to the MainActor), however `deinit` is not
            //   (we could opt into it, by marking the `deinit` `isolated`, however that's a newer feature)
            // so we aren't able to call any of the functions on `self` that are isolated.
            // for this reason, much of the code in this `deinit` is copied from the `pause` function above
            //   (since we can't call it)
            
            audioEngine.stop()
            
#if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
            if let pushedAudioSessionState {
                let audioSession: AVAudioSession = .sharedInstance()
                do {
                    try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                    try audioSession.setState(pushedAudioSessionState)
                } catch {
                    Self.logger.error("audioSession.setState -> \(error)")
                }
                self.pushedAudioSessionState = nil
            }
#endif
            let notificationCenter: NotificationCenter = .default
            for observer in defaultNotificationCenterObservers {
                notificationCenter.removeObserver(observer)
            }
        }
    }
}

extension LiveSessionManager {
    @MainActor
    @Observable
    final class Transcript {
        private static let logger = Logger(subsystem: "LiveSessionManager", category: "Transcript")
        
        private var currentAccumulator: TranscriptionAccumulator?
        
        private var completedTurns: [Turn] = []
        
        var turns: [Turn] {
            var result: [Turn] = completedTurns
            if let currentAccumulator {
                result.append(.init(transcriptionAccumulator: currentAccumulator))
            }
            return result
        }
        
        private func onPartialTranscript(role: Turn.Role, text: String) {
            if var currentAccumulator {
                if currentAccumulator.role == role {
                    currentAccumulator.text.append(text)
                    self.currentAccumulator = currentAccumulator
                } else {
                    completedTurns.append(.init(transcriptionAccumulator: currentAccumulator))
                    self.currentAccumulator = .init(role: role, text: text)
                }
            } else {
                self.currentAccumulator = .init(role: role, text: text)
            }
        }
        
        func onServerMessage(_ message: BidiGenerateContentServerMessage) {
            switch message.messageType {
            case .serverContent(let serverContent):
                if let inputTranscription = serverContent.inputTranscription {
                    onPartialTranscript(role: .user, text: inputTranscription.text)
                }
                
                if let outputTranscription = serverContent.outputTranscription {
                    onPartialTranscript(role: .model, text: outputTranscription.text)
                }
                
                if serverContent.generationComplete == true,
                   let currentAccumulator, currentAccumulator.role == .model {
                    completedTurns.append(.init(transcriptionAccumulator: currentAccumulator))
                    self.currentAccumulator = nil
                }
                
                if let modelTurn = serverContent.modelTurn {
                    if let currentAccumulator, currentAccumulator.role != .model {
                        completedTurns.append(.init(transcriptionAccumulator: currentAccumulator))
                        self.currentAccumulator = nil
                    }
                    
                    let filteredParts = modelTurn.parts.filter { part in
                        if case .inlineData(let blob) = part.data, blob.mimeType == "audio/pcm;rate=24000" {
                            return false
                        }
                        return true
                    }
                    if !filteredParts.isEmpty {
                        completedTurns.append(.init(role: .model, content: .parts(filteredParts)))
                    }
                }
            case .toolCall(let toolCall):
                guard let functionCalls = toolCall.functionCalls else {
                    return // nothing to do
                }
                let turns = functionCalls.map { functionCall in
                    Turn(role: .model, content: .functionCall(functionCall))
                }
                completedTurns.append(contentsOf: turns)
            default:
                break // currently nothing to do here
            }
        }
    }
}

extension LiveSessionManager.Transcript {
    nonisolated struct Turn: Identifiable {
        enum Role: Hashable {
            case user
            case model
        }
        
        enum Content {
            case parts([Part])
            case transcript(String)
            case functionCall(FunctionCall)
        }
        
        let id: UUID
        
        let role: Role
        let content: Content
        
        init(id: UUID = .init(), role: Role, content: Content) {
            self.id = id
            self.role = role
            self.content = content
        }
    }
}

extension LiveSessionManager.Transcript {
    nonisolated struct TranscriptionAccumulator: Identifiable {
        let id = UUID()
        
        let role: Turn.Role
        var text: String
    }
}

extension LiveSessionManager.Transcript.Turn {
    init(transcriptionAccumulator transcript: LiveSessionManager.Transcript.TranscriptionAccumulator) {
        self.init(id: transcript.id, role: transcript.role, content: .transcript(transcript.text))
    }
}

extension LiveSessionManager {
    @MainActor
    @Observable
    final class Usage: Tools.FunctionProvider {
        // select properties from `UsageMetadata` - see that type for more context
        struct TokenCount {
            /// Output only. Number of tokens in the prompt.
            ///
            /// When `cachedContent` is set, this is still the total effective prompt size meaning this includes the number of tokens in the cached content.
            var prompt: Int32
            /// Number of tokens in the cached part of the prompt (the cached content)
            var cachedContent: Int32
            /// Output only. Total number of tokens across all the generated response candidates.
            var response: Int32
            /// Output only. Number of tokens present in tool-use prompt(s).
            var toolUsePrompt: Int32
            /// Output only. Number of tokens of thoughts for thinking models.
            var thoughts: Int32
            /// Output only. Total token count for the generation request (prompt + response candidates).
            var total: Int32
        }
        
        private static let logger = Logger(subsystem: "LiveSessionManager", category: "Usage")
        
        private(set) var tokenCount: TokenCount = .init(
            prompt: 0,
            cachedContent: 0,
            response: 0,
            toolUsePrompt: 0,
            thoughts: 0,
            total: 0
        )
        
        let functionDeclarations: [FunctionDeclaration] = [
            .init(
                name: "meta_get_token_usage", description: "Get the number of tokens used in this session",
                behavior: nil,
                parameters: nil, parametersJsonSchema: nil,
                response: .object(properties: [
                    "prompt": .integer(description: "Number of tokens in the prompt"),
                    "cached_content": .integer(description: "Number of tokens in the cached part of the prompt"),
                    "response": .integer(description: "Total number of tokens across all the generated response candidates"),
                    "tool_use_prompt": .integer(description: "Number of tokens present in tool-use prompt"),
                    "thoughts": .integer(description: "Number of tokens of thoughts for thinking models"),
                    "total": .integer(description: "Total token count for the generation request"),
                ]), responseJsonSchema: nil
            )
        ]
        
        func handleFunctionCall(name: String, parameters: Protobuf.Struct) async -> Tools.ThinnedFunctionResponse {
            guard name == "meta_get_token_usage" else {
                return .init(response: [
                    "error": .string("unknown function")
                ])
            }
            
            let tokenCount = self.tokenCount
            return .init(response: [
                "prompt": .number(Double(tokenCount.prompt)),
                "cached_content": .number(Double(tokenCount.cachedContent)),
                "response": .number(Double(tokenCount.response)),
                "tool_use_prompt": .number(Double(tokenCount.toolUsePrompt)),
                "thoughts": .number(Double(tokenCount.thoughts)),
                "total": .number(Double(tokenCount.total)),
            ])
        }
        
        func onServerMessage(_ message: BidiGenerateContentServerMessage) {
            guard let usageMetadata = message.usageMetadata else { return }
            
            var tokenCount = self.tokenCount
            
            tokenCount.prompt += usageMetadata.promptTokenCount
            tokenCount.cachedContent += usageMetadata.cachedContentTokenCount
            tokenCount.response += usageMetadata.responseTokenCount
            tokenCount.toolUsePrompt += usageMetadata.toolUsePromptTokenCount
            tokenCount.thoughts += usageMetadata.thoughtsTokenCount
            tokenCount.total += usageMetadata.totalTokenCount
            
            self.tokenCount = tokenCount
        }
    }
}

extension LiveSessionManager {
    @MainActor
    @Observable
    final class Tools {
        private static let logger = Logger(subsystem: "LiveSessionManager", category: "Tools")
        
        fileprivate weak var manager: LiveSessionManager?
        
        private var runningFunctionTasks: [String: Task<Void, Never>] = [:]
        
        // ideally these should be `weak` references, since this essentially acts as a cache,
        // but currently it's not an issue to hold strong references to these
        private var functionResolver: [String: FunctionProvider] = [:]
        
        private let sysctlFunctionProvider: SysctlFunctionProvider = .init()
        
        var functionProviders: [FunctionProvider] {
            var build: [FunctionProvider] = [
                sysctlFunctionProvider,
            ]
            if let manager {
                build.append(contentsOf: [
                    manager.playground,
                    manager.usage,
                    manager.haptics
                ] as [FunctionProvider])
            }
            return build
        }
        
        func onSetup() {
            functionResolver = functionProviders.reduce(into: [:]) { partialResult, provider in
                for functionDeclaration in provider.functionDeclarations {
                    if partialResult[functionDeclaration.name] != nil {
                        Self.logger.warning("Found multiple function providers for \(functionDeclaration.name). Only the first one will be used.")
                        continue
                    }
                    partialResult[functionDeclaration.name] = provider
                }
            }
        }
        
        func onServerMessage(_ message: BidiGenerateContentServerMessage) {
            switch message.messageType {
            case .toolCall(let toolCall):
                if let functionCalls = toolCall.functionCalls {
                    for functionCall in functionCalls {
                        let functionTask = Task<Void, Never> { [weak self] in
                            let thinnedResponse: ThinnedFunctionResponse
                            
                            if let self { // not using `guard let` so that we don't continue holding a reference to `self` below
                                if let resolver = self.functionResolver[functionCall.name] {
                                    thinnedResponse = await resolver.handleFunctionCall(
                                        name: functionCall.name, parameters: functionCall.args ?? [:]
                                    )
                                } else {
                                    thinnedResponse = .init(response: [
                                        "error": .string("unknown function")
                                    ])
                                }
                            } else {
                                return
                            }
                            
                            let fullResponse = FunctionResponse(
                                id: functionCall.id,
                                name: functionCall.name,
                                response: thinnedResponse.response,
                                parts: thinnedResponse.parts,
                                willContinue: thinnedResponse.willContinue,
                                scheduling: thinnedResponse.scheduling
                            )
                            
                            guard let self else { return }
                            
                            if let manager = self.manager {
                                do {
                                    try await manager.bidiSession.send(message: .toolResponse(.init(functionResponses: [ fullResponse ])))
                                } catch {
                                    // TODO: show in UI?
                                    Self.logger.error("bidiSession.send(message: .toolResponse) -> \(error)")
                                }
                            }
                            
                            if let functionId = functionCall.id {
                                self.runningFunctionTasks.removeValue(forKey: functionId)
                            }
                        }
                        if let functionId = functionCall.id {
                            runningFunctionTasks[functionId] = functionTask
                        }
                    }
                }
            case .toolCallCancellation(let toolCallCancellation):
                for functionId in toolCallCancellation.ids {
                    // it's not particularly important to us if we find an active Task or not
                    runningFunctionTasks[functionId]?.cancel()
                }
            default:
                break // not tool related
            }
        }
    }
}

extension LiveSessionManager.Tools {
    // select properties from `FunctionResponse` - see that type for more context
    struct ThinnedFunctionResponse {
        /// The function response in JSON object format.
        ///
        /// Callers can use any keys of their choice that fit the function's syntax to return the function output, e.g. "output", "result", etc.
        /// In particular, if the function call failed to execute, the response can have an "error" key to return error details to the model.
        let response: Protobuf.Struct
        /// Ordered Parts that constitute a function response.
        ///
        /// Parts may have different IANA MIME types.
        let parts: [FunctionResponse.Part]?
        /// Signals that function call continues, and more responses will be returned, turning the function call into a generator.
        ///
        /// Is only applicable to ``FunctionDeclaration/Behavior/nonBlocking`` function calls, is ignored otherwise.
        /// If set to false, future responses will not be considered.
        /// It is allowed to return empty ``FunctionResponse/response`` with `willContinue=False` to signal that the function call is finished.
        /// This may still trigger the model generation.
        /// To avoid triggering the generation and finish the function call, additionally set ``scheduling`` to ``Scheduling/silent``.
        let willContinue: Bool?
        /// Specifies how the response should be scheduled in the conversation.
        ///
        /// Only applicable to ``FunctionDeclaration/Behavior/nonBlocking`` function calls, is ignored otherwise. Defaults to ``Scheduling/whenIdle``.
        let scheduling: FunctionResponse.Scheduling?
        
        init(response: Protobuf.Struct, parts: [FunctionResponse.Part]? = nil, willContinue: Bool? = nil, scheduling: FunctionResponse.Scheduling? = nil) {
            self.response = response
            self.parts = parts
            self.willContinue = willContinue
            self.scheduling = scheduling
        }
    }
    
    @MainActor
    protocol FunctionProvider {
        var functionDeclarations: [FunctionDeclaration] { get }
        
        func handleFunctionCall(name: String, parameters: Protobuf.Struct) async -> ThinnedFunctionResponse
    }
}

extension LiveSessionManager {
    @MainActor
    @Observable
    final class Haptics: Tools.FunctionProvider {
        enum EventDescriptor {
            case status(StatusEventDescriptor)
            case impact(ImpactDescriptor)
        }
        
        enum StatusEventDescriptor: String, CaseIterable {
            case success
            case warning
            case error
        }
        
        struct ImpactDescriptor {
            enum Weight: String, CaseIterable {
                case light
                case medium
                case heavy
            }
            
            let weight: Weight
            let intensity: Double
        }
        
        struct Request: Identifiable {
            let id: UUID
            
            let payload: EventDescriptor
            
            fileprivate let fulfillment: CheckedContinuation<Void, Never>
            
            fileprivate init(id: UUID = .init(), payload: EventDescriptor, fulfillment: CheckedContinuation<Void, Never>) {
                self.id = id
                self.payload = payload
                self.fulfillment = fulfillment
            }
        }
        
        private(set) var currentRequest: Request?
        
        private var requestQueue: [Request] = []
        
        let functionDeclarations: [FunctionDeclaration] = [
            .init(
                name: "haptic_play_status", description: "Play a haptic event based on a status",
                behavior: nil, parameters: .object(nullable: false, properties: [
                    "status": .string(format: "enum", nullable: false, enum: StatusEventDescriptor.allCases.map(\.rawValue))
                ]), parametersJsonSchema: nil, response: nil, responseJsonSchema: nil
            ),
            .init(
                name: "haptic_play_impact", description: "Play a haptic event based on a physical metaphor",
                behavior: nil, parameters: .object(nullable: false, properties: [
                    "weight": .string(
                        format: "enum", description: "Defaults to \(ImpactDescriptor.Weight.medium.rawValue)", nullable: true,
                        enum: ImpactDescriptor.Weight.allCases.map(\.rawValue)
                    ),
                    "intensity": .number(description: "Defaults to 1.0", nullable: true, minimum: 0.0, maximum: 1.0),
                ]), parametersJsonSchema: nil, response: nil, responseJsonSchema: nil
            ),
        ]
        
        private func handlePlayStatusCall(parameters: Protobuf.Struct) async -> Protobuf.Struct {
            guard let statusValue = parameters["status"] else {
                return [
                    "error": .string("missing 'status' parameter")
                ]
            }
            guard case .string(let rawStatus) = statusValue,
                  let statusDescriptor = Haptics.StatusEventDescriptor(rawValue: rawStatus) else {
                return [
                    "error": .string("unsupported 'status' value")
                ]
            }
            
            await playEventDescriptor(.status(statusDescriptor))
            
            return [
                "status": .string("success")
            ]
        }
        
        private func handlePlayImpactCall(parameters: Protobuf.Struct) async -> Protobuf.Struct {
            let weightDescriptor: Haptics.ImpactDescriptor.Weight
            
            if let weightValue = parameters["weight"] {
                guard case .string(let rawWeight) = weightValue,
                      let parsedWeight = Haptics.ImpactDescriptor.Weight(rawValue: rawWeight) else {
                    return [
                        "error": .string("unsupported 'weight' value")
                    ]
                }
                weightDescriptor = parsedWeight
            } else {
                weightDescriptor = .medium
            }
            
            let intensity: Double
            
            if let intensityValue = parameters["intensity"] {
                guard case .number(let intensityCandidate) = intensityValue,
                      (0.0)...(1.0) ~= intensityCandidate else {
                    return [
                        "error": .string("unsupported 'intensity' value")
                    ]
                }
                intensity = intensityCandidate
            } else {
                intensity = 1.0
            }
            
            await playEventDescriptor(.impact(.init(weight: weightDescriptor, intensity: intensity)))
            
            return [
                "status": .string("success")
            ]
        }
        
        func handleFunctionCall(name: String, parameters: Protobuf.Struct) async -> Tools.ThinnedFunctionResponse {
            let response: Protobuf.Struct = switch name {
            case "haptic_play_status":
                await handlePlayStatusCall(parameters: parameters)
            case "haptic_play_impact":
                await handlePlayImpactCall(parameters: parameters)
            default:
                [
                    "error": .string("unknown function")
                ]
            }
            return .init(response: response)
        }
        
        func playEventDescriptor(_ eventDescriptor: EventDescriptor) async {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                let request = Request(payload: eventDescriptor, fulfillment: continuation)
                addRequest(request)
            }
        }
        
        func addRequest(_ request: Request) {
            if currentRequest == nil {
                currentRequest = request
            } else {
                requestQueue.append(request)
            }
        }
        
        func markRequestFulfilled(_ request: Request) {
            request.fulfillment.resume()
            
            requestQueue.removeAll { $0.id == request.id }
            
            if let currentRequest, currentRequest.id == request.id {
                if requestQueue.isEmpty {
                    self.currentRequest = nil
                } else {
                    self.currentRequest = requestQueue.removeFirst()
                }
            }
        }
    }
}

extension LiveSessionManager {
    @MainActor
    @Observable
    final class Playground: Tools.FunctionProvider {
        enum ColorDescriptor: String, CaseIterable {
            case black
            case blue
            case brown
            case cyan
            case gray
            case green
            case indigo
            case mint
            case orange
            case pink
            case purple
            case red
            case teal
            case white
            case yellow
        }
        
        private static let logger = Logger(subsystem: "LiveSessionManager", category: "Playground")
        
        private(set) var isShowing: Bool = false
        private(set) var colorDescriptor: ColorDescriptor = .blue
        
        let functionDeclarations: [FunctionDeclaration] = [
            .init(
                name: "playground_set_is_showing", description: "Set if the playground should be shown to the user",
                behavior: nil, parameters: .object(nullable: false, properties: [
                    "should_show": .boolean()
                ]), parametersJsonSchema: nil, response: nil, responseJsonSchema: nil
            ),
            .init(
                name: "playground_set_color", description: "Set the color used in the playground",
                behavior: nil, parameters: .object(nullable: false, properties: [
                    "color": .string(format: "enum", nullable: false, enum: ColorDescriptor.allCases.map(\.rawValue))
                ]), parametersJsonSchema: nil, response: nil, responseJsonSchema: nil
            ),
        ]
        
        private func handleSetIsShowingCall(parameters: Protobuf.Struct) -> Protobuf.Struct {
            guard let showValue = parameters["should_show"] else {
                return [
                    "error": .string("missing 'should_show' parameter")
                ]
            }
            guard case .bool(let shouldShow) = showValue else {
                return [
                    "error": .string("unsupported 'should_show' value")
                ]
            }
            
            self.isShowing = shouldShow
            
            return [
                "status": .string("success")
            ]
        }
        
        private func handleSetColorCall(parameters: Protobuf.Struct) -> Protobuf.Struct {
            guard let colorValue = parameters["color"] else {
                return [
                    "error": .string("missing 'color' parameter")
                ]
            }
            guard case .string(let rawColor) = colorValue,
                  let colorDescriptor = Playground.ColorDescriptor(rawValue: rawColor) else {
                return [
                    "error": .string("unsupported 'color' value")
                ]
            }
            
            self.colorDescriptor = colorDescriptor
            
            return [
                "status": .string("success")
            ]
        }
        
        func handleFunctionCall(name: String, parameters: Protobuf.Struct) async -> Tools.ThinnedFunctionResponse {
            let response: Protobuf.Struct = switch name {
            case "playground_set_is_showing":
                handleSetIsShowingCall(parameters: parameters)
            case "playground_set_color":
                handleSetColorCall(parameters: parameters)
            default:
                [
                    "error": .string("unknown function")
                ]
            }
            return .init(response: response)
        }
    }
}
