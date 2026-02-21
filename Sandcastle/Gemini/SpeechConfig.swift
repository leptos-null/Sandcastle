//
//  SpeechConfig.swift
//  Sandcastle
//
//  Created by Leptos on 2/20/26.
//

import Foundation

/// The speech generation config.
///
/// <https://ai.google.dev/api/generate-content#SpeechConfig>
struct SpeechConfig: Codable {
    /// The configuration in case of single-voice output.
    let voiceConfig: VoiceConfig?
    /// The configuration for the multi-speaker setup.
    ///
    /// It is mutually exclusive with the ``SpeechConfig/voiceConfig`` field.
    let multiSpeakerVoiceConfig: MultiSpeakerVoiceConfig?
    /// Language code (in BCP 47 format, e.g. "en-US") for speech synthesis.
    ///
    /// Valid values are:
    /// de-DE, en-AU, en-GB, en-IN, en-US, es-US, fr-FR, hi-IN, pt-BR, ar-XA,
    /// es-ES, fr-CA, id-ID, it-IT, ja-JP, tr-TR, vi-VN, bn-IN, gu-IN, kn-IN,
    /// ml-IN, mr-IN, ta-IN, te-IN, nl-NL, ko-KR, cmn-CN, pl-PL, ru-RU, and th-TH.
    let languageCode: String?
}
