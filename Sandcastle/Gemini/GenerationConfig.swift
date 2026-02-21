//
//  GenerationConfig.swift
//  Sandcastle
//
//  Created by Leptos on 2/20/26.
//

import Foundation

/// Configuration options for model generation and outputs.
///
/// Not all parameters are configurable for every model.
///
/// <https://ai.google.dev/api/generate-content#generationconfig>
struct GenerationConfig: Codable {
    // this declaration is not complete - see documentation above for all fields
    
    /// The requested modalities of the response.
    ///
    /// Represents the set of modalities that the model can return, and should be expected in the response.
    /// This is an exact match to the modalities of the response.
    /// A model may have multiple combinations of supported modalities.
    /// If the requested modalities do not match any of the supported combinations, an error will be returned.
    /// An empty list is equivalent to requesting only text.
    let responseModalities: [Self.Modality]?
    /// The maximum number of tokens to include in a response candidate.
    ///
    /// - Note: The default value varies by model, see the `Model.output_token_limit` attribute of the Model returned from the getModel function.
    let maxOutputTokens: Int?
    /// Presence penalty applied to the next token's logprobs if the token has already been seen in the response.
    ///
    /// This penalty is binary on/off and not dependent on the number of times the token is used (after the first).
    /// Use ``frequencyPenalty`` or a penalty that increases with each use.
    ///
    /// A positive penalty will discourage the use of tokens that have already been used in the response, increasing the vocabulary.
    /// A negative penalty will encourage the use of tokens that have already been used in the response, decreasing the vocabulary.
    let presencePenalty: Double?
    /// Frequency penalty applied to the next token's logprobs, multiplied by the number of times each token has been seen in the response so far.
    ///
    /// A positive penalty will discourage the use of tokens that have already been used, proportional to the number of times the token has been used: The more a token is used, the more difficult it is for the model to use that token again increasing the vocabulary of responses.
    ///
    /// Caution: A negative penalty will encourage the model to reuse tokens proportional to the number of times the token has been used.
    /// Small negative values will reduce the vocabulary of a response.
    /// Larger negative values will cause the model to start repeating a common token until it hits the ``maxOutputTokens`` limit.
    let frequencyPenalty: Double?
    /// Enables enhanced civic answers. It may not be available for all models.
    let enableEnhancedCivicAnswers: Bool?
    /// The speech generation config.
    let speechConfig: SpeechConfig?
    /// Config for thinking features.
    ///
    /// An error will be returned if this field is set for models that don't support thinking.
    let thinkingConfig: ThinkingConfig?
    /// Config for image generation. An error will be returned if this field is set for models that don't support these config options.
    let imageConfig: ImageConfig?
    /// If specified, the media resolution specified will be used.
    let mediaResolution: MediaResolution?
}

extension GenerationConfig {
    /// Supported modalities of the response.
    ///
    /// <https://ai.google.dev/api/generate-content#Modality>
    enum Modality: String, Codable {
        /// Default value.
        case unspecified = "MODALITY_UNSPECIFIED"
        /// Indicates the model should return text.
        case text = "TEXT"
        /// Indicates the model should return images.
        case image = "IMAGE"
        /// Indicates the model should return audio.
        case audio = "AUDIO"
    }
}
