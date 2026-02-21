//
//  FunctionDeclaration.swift
//  Sandcastle
//
//  Created by Leptos on 2/19/26.
//

import Foundation

/// Structured representation of a function declaration as defined by the [OpenAPI 3.03 specification](<https://spec.openapis.org/oas/v3.0.3>).
///
/// Included in this declaration are the function name and parameters.
/// This `FunctionDeclaration` is a representation of a block of code that can be used as a `Tool` by the model and executed by the client.
///
/// <https://ai.google.dev/api/caching#FunctionDeclaration>
struct FunctionDeclaration: Codable {
    /// The name of the function.
    ///
    /// Must be a-z, A-Z, 0-9, or contain underscores, colons, dots, and dashes, with a maximum length of 64.
    let name: String
    /// A brief description of the function.
    let description: String
    /// Specifies the function Behavior.
    ///
    /// Currently only supported by the `BidiGenerateContent` method.
    let behavior: Behavior?
    /// Describes the parameters to this function.
    ///
    /// Reflects the Open API 3.03 Parameter Object
    ///   string Key: the name of the parameter. Parameter names are case sensitive.
    ///   Schema Value: the Schema defining the type used for the parameter.
    let parameters: Schema?
    /// Describes the parameters to the function in JSON Schema format.
    ///
    /// The schema must describe an object where the properties are the parameters to the function. For example:
    /// ```json
    /// {
    ///   "type": "object",
    ///   "properties": {
    ///     "name": { "type": "string" },
    ///     "age": { "type": "integer" }
    ///   },
    ///   "additionalProperties": false,
    ///   "required": ["name", "age"],
    ///   "propertyOrdering": ["name", "age"]
    /// }
    /// ```
    /// This field is mutually exclusive with ``FunctionDeclaration/parameters``.
    let parametersJsonSchema: AnyJson?
    /// Describes the output from this function in JSON Schema format.
    /// Reflects the Open API 3.03 Response Object. The Schema defines the type used for the response value of the function.
    let response: Schema?
    /// Describes the output from this function in JSON Schema format.
    ///
    /// The value specified by the schema is the response value of the function.
    /// This field is mutually exclusive with ``FunctionDeclaration/response``.
    let responseJsonSchema: AnyJson?
}

extension FunctionDeclaration {
    /// Defines the function behavior.
    ///
    /// Defaults to ``FunctionDeclaration/Behavior/blocking``.
    ///
    /// <https://ai.google.dev/api/caching#Behavior>
    enum Behavior: String, Codable {
        /// This value is unused.
        case unspecified = "UNSPECIFIED"
        /// If set, the system will wait to receive the function response before continuing the conversation.
        case blocking = "BLOCKING"
        /// If set, the system will not wait to receive the function response.
        /// Instead, it will attempt to handle function responses as they become available while maintaining the conversation between the user and the model.
        case nonBlocking = "NON_BLOCKING"
    }
}
