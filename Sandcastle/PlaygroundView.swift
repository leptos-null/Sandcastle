//
//  PlaygroundView.swift
//  Sandcastle
//
//  Created by Leptos on 2/25/26.
//

import SwiftUI

struct PlaygroundView: View {
    let playground: LiveSessionManager.Playground
    
    var body: some View {
        VStack {
            Text("Playground")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Circle()
                .fill(Color(playground.colorDescriptor))
                .animation(.snappy, value: playground.colorDescriptor)
        }
        .padding(16)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
    }
}

extension SwiftUI.Color {
    init(_ playgroundColorDescriptor: LiveSessionManager.Playground.ColorDescriptor) {
        self = switch playgroundColorDescriptor {
        case .black: .black
        case .blue: .blue
        case .brown: .brown
        case .cyan: .cyan
        case .gray: .gray
        case .green: .green
        case .indigo: .indigo
        case .mint: .mint
        case .orange: .orange
        case .pink: .pink
        case .purple: .purple
        case .red: .red
        case .teal: .teal
        case .white: .white
        case .yellow: .yellow
        }
    }
}
