//
//  ContentView.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import SwiftUI

struct ContentView: View {
    @State private var liveSession = LiveSessionManager()
    
    var body: some View {
        ScrollView(.vertical) {
            VStack {
                ForEach(liveSession.transcript.turns) { (turn: LiveSessionManager.Transcript.Turn) in
                    Group {
                        switch turn.content {
                        case .parts(let parts):
                            ForEach(parts.enumerated(), id: \.offset) { partOffset, part in
                                PartView(part: part)
                            }
                        case .transcript(let string):
                            TranscriptEntryView {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(string)
                                    
                                    Label("Transcript", systemImage: "waveform")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        case .functionCall(let functionCall):
                            TranscriptFunctionCallView(functionCall: functionCall)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: (turn.role == .user) ? .trailing : .leading)
                    .padding((turn.role == .user) ? .leading : .trailing, 16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scenePadding()
        }
        .defaultScrollAnchor(.bottom, for: .sizeChanges)
        .overlay {
            if liveSession.transcript.turns.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "microphone")
                        .accessibilityHidden(true)
                    Text("Double-tap anywhere to mute or unmute")
                        .font(.callout)
                }
                .animation(.easeInOut(duration: 0.625)) { placeholder in
                    placeholder
                        .opacity(liveSession.audio.isRunning ? 1 : 0)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scenePadding()
                .transition(.opacity)
            }
        }
        .animation(.default, value: liveSession.transcript.turns.map(\.id))
        .safeAreaInset(edge: .bottom) {
            if liveSession.playground.isShowing {
                PlaygroundView(playground: liveSession.playground)
                    .frame(maxHeight: 240)
                    .scenePadding()
                    .transition(.scale(0.125, anchor: .bottom).combined(with: .opacity))
            }
        }
        .safeAreaInset(edge: .bottom) {
            ZStack(alignment: .bottom) {
                SpectrumAnalyzerView(spectrumAnalyzer: liveSession.audio.inputAudioAnalyzer, shading: .color(.orange))
                SpectrumAnalyzerView(spectrumAnalyzer: liveSession.audio.outputAudioAnalyzer, shading: .color(.indigo))
            }
            .frame(height: 120)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .safeAreaInset(edge: .top) {
            if let error = liveSession.recentError {
                Text(error.localizedDescription)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white) // to contrast against `.red`
                    .background(.red, in: .rect(cornerRadius: 12))
                    .scenePadding()
            }
        }
        .animation(.default, value: liveSession.playground.isShowing)
        .animation(.default, value: liveSession.recentError != nil)
        .contentShape(.rect)
        .onTapGesture(count: 2) {
            liveSession.audio.isMuted.toggle()
        }
        .onAppear {
            liveSession.startIfNeeded()
        }
    }
}
