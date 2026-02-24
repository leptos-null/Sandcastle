//
//  BidiGenerateContentSetup.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// Message to be sent in the first (and only in the first) ``BidiGenerateContentClientMessage``.
/// Contains configuration that will apply for the duration of the streaming RPC.
///
/// Clients should wait for a ``BidiGenerateContentSetupComplete`` message before sending any additional messages.
///
/// <https://ai.google.dev/api/live#bidigeneratecontentsetup>
struct BidiGenerateContentSetup: Codable {
    /// The model's resource name. This serves as an ID for the Model to use.
    ///
    /// Format: `models/{model}`
    let model: String
    /// Generation config.
    ///
    /// The following fields are not supported:
    /// - `responseLogprobs`
    /// - `responseMimeType`
    /// - `logprobs`
    /// - `responseSchema`
    /// - `stopSequence`
    /// - `routingConfig`
    /// - `audioTimestamp`
    let generationConfig: GenerationConfig?
    /// The user provided system instructions for the model.
    ///
    /// - Note: Only text should be used in parts and content in each part will be in a separate paragraph.
    let systemInstruction: Content?
    /// A list of `Tools` the model may use to generate the next response.
    ///
    /// A ``Tool`` is a piece of code that enables the system to interact with external systems to perform an action, or set of actions, outside of knowledge and scope of the model.
    let tools: [Tool]?
    /// Configures the handling of realtime input.
    let realtimeInputConfig: RealtimeInputConfig?
    /// Configures session resumption mechanism.
    ///
    /// If included, the server will send ``SessionResumptionUpdate`` messages.
    let sessionResumption: SessionResumptionConfig?
    /// Configures a context window compression mechanism.
    ///
    /// If included, the server will automatically reduce the size of the context when it exceeds the configured length.
    let contextWindowCompression: ContextWindowCompressionConfig?
    /// If set, enables transcription of voice input.
    ///
    /// The transcription aligns with the input audio language, if configured.
    let inputAudioTranscription: AudioTranscriptionConfig?
    /// If set, enables transcription of the model's audio output.
    ///
    /// The transcription aligns with the language code specified for the output audio, if configured.
    let outputAudioTranscription: AudioTranscriptionConfig?
    /// Configures the proactivity of the model.
    ///
    /// This allows the model to respond proactively to the input and to ignore irrelevant input.
    ///
    /// - Note: At the time of writing, requires ``BidiGenerateContentSession/InterfaceVersion/v1alpha``
    /// per <https://ai.google.dev/gemini-api/docs/live-guide#proactive-audio>
    let proactivity: ProactivityConfig?
}
