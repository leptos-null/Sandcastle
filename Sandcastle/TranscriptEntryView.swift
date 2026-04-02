//
//  TranscriptEntryView.swift
//  Sandcastle
//
//  Created by Leptos on 2/26/26.
//

import SwiftUI

struct TranscriptEntryView<T: View>: View {
    let content: () -> T
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundStyle: some ShapeStyle {
        let opacity: Double = switch colorScheme {
        case .light: 0.95
        case .dark: 0.8
        @unknown default: 0.85
        }
        return .background.opacity(opacity)
    }
    
    init(@ViewBuilder content: @escaping () -> T) {
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(12)
            .background(backgroundStyle, in: .rect(cornerRadius: 12))
    }
}
