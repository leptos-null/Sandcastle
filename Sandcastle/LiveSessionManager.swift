//
//  LiveSessionManager.swift
//  Sandcastle
//
//  Created by Leptos on 2/21/26.
//

import Foundation
import AVFoundation
import OSLog

@MainActor
final class LiveSessionManager {
    private enum State {
        case idle
        case connecting
        case connected
        case setup
    }
    
    private static let logger = Logger(subsystem: "LiveSessionManager", category: "Root")
    
    let bidiSession: BidiGenerateContentSession = .init()
    
    private var state: State = .idle
    
    let audio = Audio()
    
    init() {
        audio.manager = self
    }
    
    func start() throws {
        guard case .idle = state else {
            throw StateError()
        }
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
                }
            } catch {
                Self.logger.error("Connection error: \(error)")
            }
            self?.state = .idle
        }
    }
    
    private func setup() async throws {
        guard case .connected = state else {
            throw StateError()
        }
        
        let setup: BidiGenerateContentSetup = .init(
            model: "models/gemini-2.5-flash-native-audio-preview-12-2025",
            generationConfig: .init(
                responseModalities: [ .audio ],
                enableAffectiveDialog: true,
            ),
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
    final class Audio {
        private static let logger = Logger(subsystem: "LiveSessionManager", category: "Audio")
        
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
        
        fileprivate weak var manager: LiveSessionManager?
        
        private var isSetup: Bool = false
        private var wantsRunning: Bool = false
        
        private var defaultNotificationCenterObservers: [NSObjectProtocol] = []
        
        
        func setupIfNeeded() throws {
            if isSetup { return }
            
            // because this code (currently) only runs once per `audioEngine` lifetime,
            // the code must not depend on the `audioEngine.inputNode` audio format, since that may change.
            // see the doc comment for `AVAudioEngineConfigurationChangeNotification` for more info.
            
            audioEngine.attach(playerNode)
            
            let inputNode = audioEngine.inputNode
            try inputNode.setVoiceProcessingEnabled(true)
            
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
            let bufferConverter = AudioBufferConverter()
            
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
                        targetBuffer = try await bufferConverter.convert(buffer: buffer, to: targetListenFormat)
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
#if os(iOS) || os(watchOS) || os(tvOS)
            // TODO: push AVAudioSession state
            let audioSession: AVAudioSession = .sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.bluetoothHighQualityRecording, .allowBluetoothHFP, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
#endif
            try audioEngine.start()
        }
        
        func pause() {
            wantsRunning = false
            audioEngine.stop()
            
#if os(iOS) || os(watchOS) || os(tvOS)
            // TODO: pop AVAudioSession state if needed
#endif
        }
        
        deinit {
            audioEngine.stop()
            
#if os(iOS) || os(watchOS) || os(tvOS)
            // TODO: pop AVAudioSession state if needed
#endif
            let notificationCenter: NotificationCenter = .default
            for observer in defaultNotificationCenterObservers {
                notificationCenter.removeObserver(observer)
            }
        }
    }
}
