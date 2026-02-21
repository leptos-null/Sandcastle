//
//  SessionResumptionConfig.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// Session resumption configuration.
///
/// This message is included in the session configuration as ``BidiGenerateContentSetup/sessionResumption``.
/// If configured, the server will send ``SessionResumptionUpdate`` messages.
///
/// <https://ai.google.dev/api/live#sessionresumptionconfig>
struct SessionResumptionConfig: Codable {
    /// The handle of a previous session. If not present then a new session is created.
    ///
    /// Session handles come from ``SessionResumptionUpdate/token`` values in previous connections.
    let handle: String?
}
