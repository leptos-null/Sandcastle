//
//  ColorDescriptor+SwiftUI.swift
//  Sandcastle
//
//  Created by Leptos on 4/5/26.
//

import SwiftUI

extension SwiftUI.Color {
    init(_ components: ColorDescriptor.RGB) {
        self.init(
            red: Double(components.red)/255.0,
            green: Double(components.green)/255.0,
            blue: Double(components.blue)/255.0
        )
    }
    
    init(_ components: ColorDescriptor.HSB) {
        self.init(
            hue: components.hue/360.0,
            saturation: components.saturation/100.0,
            brightness: components.brightness/100.0
        )
    }
    
    init(_ name: ColorDescriptor.Name) {
        self = switch name {
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
    
    init(_ colorDescriptor: ColorDescriptor) {
        switch colorDescriptor {
        case .rgb(let components):
            self.init(components)
        case .hsb(let components):
            self.init(components)
        case .name(let name):
            self.init(name)
        }
    }
}
