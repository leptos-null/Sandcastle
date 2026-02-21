//
//  FunctionResponse.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// The result output from a ``FunctionCall`` that contains a string representing the ``FunctionDeclaration/name`` and a structured JSON object containing any output from the function is used as context to the model. This should contain the result of a ``FunctionCall`` made based on model prediction.
///
///
/// <https://ai.google.dev/api/caching#FunctionResponse>
struct FunctionResponse: Codable {
    /// The id of the function call this response is for.
    ///
    /// Populated by the client to match the corresponding function call ``FunctionCall/id``.
    let id: String?
    /// The name of the function to call.
    ///
    /// Must be a-z, A-Z, 0-9, or contain underscores and dashes, with a maximum length of 64.
    let name: String
    /// The function response in JSON object format.
    ///
    /// Callers can use any keys of their choice that fit the function's syntax to return the function output, e.g. "output", "result", etc.
    /// In particular, if the function call failed to execute, the response can have an "error" key to return error details to the model.
    let response: AnyJson
    /// Ordered Parts that constitute a function response.
    ///
    /// Parts may have different IANA MIME types.
    let parts: [Self.Part]?
    /// Signals that function call continues, and more responses will be returned, turning the function call into a generator.
    ///
    /// Is only applicable to ``FunctionDeclaration/Behavior/nonBlocking`` function calls, is ignored otherwise.
    /// If set to false, future responses will not be considered.
    /// It is allowed to return empty ``FunctionResponse/response`` with `willContinue=False` to signal that the function call is finished.
    /// This may still trigger the model generation.
    /// To avoid triggering the generation and finish the function call, additionally set ``scheduling`` to ``Scheduling/silent``.
    let willContinue: Bool?
    /// Specifies how the response should be scheduled in the conversation.
    ///
    /// Only applicable to ``FunctionDeclaration/Behavior/nonBlocking`` function calls, is ignored otherwise. Defaults to ``Scheduling/whenIdle``.
    let scheduling: Scheduling?
}

extension FunctionResponse {
    /// A datatype containing media that is part of a FunctionResponse message.
    ///
    /// A `FunctionResponsePart` consists of data which has an associated datatype.
    /// A `FunctionResponsePart` can only contain one of the accepted types in FunctionResponsePart.data.
    ///
    /// A `FunctionResponsePart` must have a fixed IANA MIME type identifying the type and subtype of the media if the `inlineData` field is filled with raw bytes.
    ///
    /// <https://ai.google.dev/api/caching#FunctionResponsePart>
    struct Part: Codable {
        // this declaration is not complete - see documentation above for all fields
    }
    
    /// Raw media bytes for function response.
    ///
    /// Text should not be sent as raw bytes, use the ``FunctionResponse/response`` field.
    ///
    /// <https://ai.google.dev/api/caching#FunctionResponseBlob>
    struct Blob: Codable {
        /// The IANA standard MIME type of the source data.
        ///
        /// Examples:
        /// - image/png
        /// - image/jpeg
        ///
        /// If an unsupported MIME type is provided, an error will be returned.
        /// For a complete list of supported types, see [Supported file formats](<https://ai.google.dev/gemini-api/docs/prompting_with_media#supported_file_formats>).
        let mimeType: String
        /// Raw bytes for media formats.
        ///
        /// A base64-encoded string.
        let data: String
    }
}

extension FunctionResponse {
    /// Specifies how the response should be scheduled in the conversation.
    ///
    /// <https://ai.google.dev/api/caching#Scheduling>
    enum Scheduling: String, Codable {
        /// This value is unused.
        case unspecified = "SCHEDULING_UNSPECIFIED"
        /// Only add the result to the conversation context, do not interrupt or trigger generation.
        case silent = "SILENT"
        /// Add the result to the conversation context, and prompt to generate output without interrupting ongoing generation.
        case whenIdle = "WHEN_IDLE"
        /// Add the result to the conversation context, interrupt ongoing generation and prompt to generate output.
        case interrupt = "INTERRUPT"
    }
}
