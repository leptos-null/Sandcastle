//
//  Config.swift
//  Sandcastle
//
//  Created by Leptos on 3/24/26.
//

protocol SecretsProvider {
    // reminder that shipping an API key in a client app is not secure.
    // this is for the convenience of a prototype app.
    static var geminiApiKey: String { get }
}

// if you're cloning this repo:
//   - create `Config+Secrets.swift` in this directory (the path is already in `.gitignore`)
//   - fill in the protocol conformance there
enum Config: SecretsProvider {
}
