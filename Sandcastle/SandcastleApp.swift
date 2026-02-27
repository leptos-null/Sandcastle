//
//  SandcastleApp.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import SwiftUI

@main
struct SandcastleApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
                    .navigationTitle("Sandcastle")
            }
        }
    }
}
