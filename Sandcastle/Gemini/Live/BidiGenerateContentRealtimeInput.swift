//
//  BidiGenerateContentRealtimeInput.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// User input that is sent in real time.
///
/// The different modalities (audio, video and text) are handled as concurrent streams. The ordering across these streams is not guaranteed.
///
/// This is different from ``BidiGenerateContentClientContent`` in a few ways:
/// - Can be sent continuously without interruption to model generation.
/// - If there is a need to mix data interleaved across the ``BidiGenerateContentClientContent`` and the ``BidiGenerateContentRealtimeInput``, the server attempts to optimize for best response, but there are no guarantees.
/// - End of turn is not explicitly specified, but is rather derived from user activity (for example, end of speech).
/// - Even before the end of turn, the data is processed incrementally to optimize for a fast start of the response from the model.
///
/// <https://ai.google.dev/api/live#bidigeneratecontentrealtimeinput>
struct BidiGenerateContentRealtimeInput: Codable {
    /// These form the realtime audio input stream.
    let audio: Blob?
    /// These form the realtime video input stream.
    let video: Blob?
    /// Marks the start of user activity.
    ///
    /// This can only be sent if automatic (i.e. server-side) activity detection is disabled.
    let activityStart: ActivityStart?
    /// Marks the end of user activity.
    ///
    /// This can only be sent if automatic (i.e. server-side) activity detection is disabled.
    let activityEnd: ActivityEnd?
    /// Indicates that the audio stream has ended, e.g. because the microphone was turned off.
    ///
    /// This should only be sent when automatic activity detection is enabled (which is the default).
    ///
    /// The client can reopen the stream by sending an audio message.
    let audioStreamEnd: Bool?
    /// These form the realtime text input stream.
    let text: String?
    
    init(audio: Blob? = nil, video: Blob? = nil, activityStart: ActivityStart? = nil, activityEnd: ActivityEnd? = nil, audioStreamEnd: Bool? = nil, text: String? = nil) {
        self.audio = audio
        self.video = video
        self.activityStart = activityStart
        self.activityEnd = activityEnd
        self.audioStreamEnd = audioStreamEnd
        self.text = text
    }
}
