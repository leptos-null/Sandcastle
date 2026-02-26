//
//  VoiceMetadata.swift
//  Sandcastle
//
//  Created by Leptos on 2/25/26.
//

import Foundation

// per <https://ai.google.dev/gemini-api/docs/live-guide#change-voice-and-language>
// > models support any of the voices available for our [Text-to-Speech (TTS)](<https://ai.google.dev/gemini-api/docs/speech-generation#voices>) models.

struct VoiceMetadata {
    let name: String
    let brief: String
}

extension VoiceMetadata {
    static let zephyr: Self = .init(name: "Zephyr", brief: "Bright")
    static let puck: Self = .init(name: "Puck", brief: "Upbeat")
    static let charon: Self = .init(name: "Charon", brief: "Informative")
    static let kore: Self = .init(name: "Kore", brief: "Firm")
    static let fenrir: Self = .init(name: "Fenrir", brief: "Excitable")
    static let leda: Self = .init(name: "Leda", brief: "Youthful")
    static let orus: Self = .init(name: "Orus", brief: "Firm")
    static let aoede: Self = .init(name: "Aoede", brief: "Breezy")
    static let callirrhoe: Self = .init(name: "Callirrhoe", brief: "Easy-going")
    static let autonoe: Self = .init(name: "Autonoe", brief: "Bright")
    static let enceladus: Self = .init(name: "Enceladus", brief: "Breathy")
    static let iapetus: Self = .init(name: "Iapetus", brief: "Clear")
    static let umbriel: Self = .init(name: "Umbriel", brief: "Easy-going")
    static let algieba: Self = .init(name: "Algieba", brief: "Smooth")
    static let despina: Self = .init(name: "Despina", brief: "Smooth")
    static let erinome: Self = .init(name: "Erinome", brief: "Clear")
    static let algenib: Self = .init(name: "Algenib", brief: "Gravelly")
    static let rasalgethi: Self = .init(name: "Rasalgethi", brief: "Informative")
    static let laomedeia: Self = .init(name: "Laomedeia", brief: "Upbeat")
    static let achernar: Self = .init(name: "Achernar", brief: "Soft")
    static let alnilam: Self = .init(name: "Alnilam", brief: "Firm")
    static let schedar: Self = .init(name: "Schedar", brief: "Even")
    static let gacrux: Self = .init(name: "Gacrux", brief: "Mature")
    static let pulcherrima: Self = .init(name: "Pulcherrima", brief: "Forward")
    static let achird: Self = .init(name: "Achird", brief: "Friendly")
    static let zubenelgenubi: Self = .init(name: "Zubenelgenubi", brief: "Casual")
    static let vindemiatrix: Self = .init(name: "Vindemiatrix", brief: "Gentle")
    static let sadachbia: Self = .init(name: "Sadachbia", brief: "Lively")
    static let sadaltager: Self = .init(name: "Sadaltager", brief: "Knowledgeable")
    static let sulafat: Self = .init(name: "Sulafat", brief: "Warm")
}

extension VoiceMetadata: CaseIterable {
    static let allCases: [Self] = [
        .zephyr, .puck, .charon,
        .kore, .fenrir, .leda,
        .orus, .aoede, .callirrhoe,
        .autonoe, .enceladus, .iapetus,
        .umbriel, .algieba, .despina,
        .erinome, .algenib, .rasalgethi,
        .laomedeia, .achernar, .alnilam,
        .schedar, .gacrux, .pulcherrima,
        .achird, .zubenelgenubi, .vindemiatrix,
        .sadachbia, .sadaltager, .sulafat,
    ]
}

extension VoiceConfig {
    init(voiceMetadata: VoiceMetadata) {
        let prebuilt: PrebuiltVoiceConfig = .init(voiceName: voiceMetadata.name)
        self.init(value: .prebuiltVoiceConfig(prebuilt))
    }
}
