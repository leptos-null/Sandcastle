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
