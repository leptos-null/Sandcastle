//
//  ActivityHandling.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// The different ways of handling user activity.
///
/// <https://ai.google.dev/api/live#activityhandling>
enum ActivityHandling: String, Codable {
    /// If unspecified, the default behavior is ``ActivityHandling/startInterrupts``.
    case unspecified = "ACTIVITY_HANDLING_UNSPECIFIED"
    /// If true, start of activity will interrupt the model's response (also called "barge in").
    /// The model's current response will be cut-off in the moment of the interruption.
    ///
    /// This is the default behavior.
    case startInterrupts = "START_OF_ACTIVITY_INTERRUPTS"
    /// The model's response will not be interrupted.
    case noInterruption = "NO_INTERRUPTION"
}
