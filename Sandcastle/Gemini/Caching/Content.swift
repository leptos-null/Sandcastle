//
//  Content.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// The base structured datatype containing multi-part content of a message.
///
/// A `Content` includes a ``role`` field designating the producer of the `Content` and a `parts` field containing multi-part data that contains the content of the message turn.
///
/// <https://ai.google.dev/api/caching#Content>
struct Content: Codable {
    /// Ordered `Parts` that constitute a single message.
    ///
    /// Parts may have different MIME types.
    let parts: [Part]
    /// The producer of the content. Must be either 'user' or 'model'.
    ///
    /// Useful to set for multi-turn conversations, otherwise can be left blank or unset.
    let role: String?
}
