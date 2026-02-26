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
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: (turn.role == .user) ? .trailing : .leading)
                    .padding((turn.role == .user) ? .leading : .trailing, 16)
                }
            }
            .scenePadding()
        }
        .defaultScrollAnchor(.bottom, for: .sizeChanges)
        .animation(.default, value: liveSession.transcript.turns.map(\.id))
        .safeAreaInset(edge: .bottom) {
            if liveSession.playground.isShowing {
                PlaygroundView(playground: liveSession.playground)
                    .frame(maxHeight: 240)
                    .scenePadding()
                    .transition(.scale(0.125, anchor: .bottom).combined(with: .opacity))
            }
        }
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
        .onAppear {
            liveSession.startIfNeeded()
        }
    }
}
