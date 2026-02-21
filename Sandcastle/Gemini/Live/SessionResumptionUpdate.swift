//
//  SessionResumptionUpdate.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// Update of the session resumption state.
///
/// Only sent if ``BidiGenerateContentSetup/sessionResumption`` was set.
///
/// <https://ai.google.dev/api/live#sessionresumptionupdate>
struct SessionResumptionUpdate: Codable {
    /// New handle that represents a state that can be resumed.
    ///
    /// Empty if ``SessionResumptionUpdate/resumable``=`false`.
    let newHandle: String
    /// True if the current session can be resumed at this point.
    ///
    /// Resumption is not possible at some points in the session.
    /// For example, when the model is executing function calls or generating.
    /// Resuming the session (using a previous session token) in such a state will result in some data loss.
    /// In these cases, ``SessionResumptionUpdate/newHandle`` will be empty and `resumable` will be false.
    let resumable: Bool
}
