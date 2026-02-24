//
//  Schema.swift
//  Sandcastle
//
//  Created by Leptos on 2/20/26.
//

import Foundation

/// The `Schema` object allows the definition of input and output data types.
///
/// These types can be objects, but also primitives and arrays.
/// Represents a select subset of an [OpenAPI 3.0 schema object](<https://spec.openapis.org/oas/v3.0.3#schema>).
///
/// <https://ai.google.dev/api/caching#Schema>
struct Schema: Codable {
    /// Data type.
    let type: SchemaType
    /// The format of the data.
    ///
    /// Any value is allowed, but most do not trigger any special functionality.
    let format: String?
    /// The title of the schema.
    let title: String?
    /// A brief description of the parameter.
    ///
    /// This could contain examples of use. Parameter description may be formatted as Markdown.
    let description: String?
    /// Indicates if the value may be null.
    let nullable: Bool?
    /// Possible values of the element of ``SchemaType/string`` with enum format.
    ///
    /// For example we can define an Enum Direction as: `{type:STRING, format:enum, enum:["EAST", NORTH", "SOUTH", "WEST"]}`
    let `enum`: [String]?
    /// Maximum number of the elements for ``SchemaType/array``.
    ///
    /// `Int64`
    let maxItems: String?
    /// Minimum number of the elements for ``SchemaType/array``.
    ///
    /// `Int64`
    let minItems: String?
    /// Properties of ``SchemaType/object``.
    ///
    /// An object containing a list of `"key": value` pairs.
    /// Example: `{ "name": "wrench", "mass": "1.3kg", "count": "3" }`.
    let properties: [String: Schema]?
    /// Required properties of ``SchemaType/object``.
    let required: [String]?
    /// Minimum number of the properties for ``SchemaType/object``.
    ///
    /// `Int64`
    let minProperties: String?
    /// Maximum number of the properties for ``SchemaType/object``.
    ///
    /// `Int64`
    let maxProperties: String?
    /// Minimum length of the ``SchemaType/string``.
    ///
    /// `Int64`
    let minLength: String?
    /// Maximum length of the ``SchemaType/string``.
    ///
    /// `Int64`
    let maxLength: String?
    /// Pattern of the ``SchemaType/string`` to restrict a string to a regular expression.
    let pattern: String?
    /// Example of the object.
    ///
    /// Will only populated when the object is the root.
    let example: AnyJson?
    /// The value should be validated against any (one or more) of the subschemas in the list.
    let anyOf: [Schema]?
    /// The order of the properties. Not a standard field in open api spec. Used to determine the order of the properties in the response.
    let propertyOrdering: [String]?
    
    /*
     * field omitted: "default" (not helpful in this context)
     */
    
    /// Schema of the elements of ``SchemaType/array``.
    let items: IndirectOptional<Schema>
    /// Minimum value of the ``SchemaType/integer`` and ``SchemaType/number``
    let minimum: Double?
    /// Maximum value of the ``SchemaType/integer`` and ``SchemaType/number``
    let maximum: Double?
}

/// Type contains the list of OpenAPI data types as defined by <https://spec.openapis.org/oas/v3.0.3#data-types>
///
/// <https://ai.google.dev/api/caching#Type>
enum SchemaType: String, Codable {
    /// Not specified, should not be used.
    case unspecified = "TYPE_UNSPECIFIED"
    /// String type.
    case string = "STRING"
    /// Number type.
    case number = "NUMBER"
    /// Integer type.
    case integer = "INTEGER"
    /// Boolean type.
    case boolean = "BOOLEAN"
    /// Array type.
    case array = "ARRAY"
    /// Object type.
    case object = "OBJECT"
    /// Null type.
    case null = "NULL"
}

extension Schema {
    static func string(
        format: String? = nil,
        title: String? = nil, description: String? = nil,
        nullable: Bool? = nil,
        `enum`: [String]? = nil,
        minLength: String? = nil, maxLength: String? = nil,
        pattern: String? = nil,
        example: AnyJson? = nil
    ) -> Self {
        .init(
            type: .string,
            format: format,
            title: title, description: description,
            nullable: nullable,
            enum: `enum`,
            maxItems: nil, minItems: nil,
            properties: nil, required: nil,
            minProperties: nil, maxProperties: nil,
            minLength: minLength, maxLength: maxLength,
            pattern: pattern,
            example: example,
            anyOf: nil,
            propertyOrdering: nil,
            items: nil,
            minimum: nil, maximum: nil
        )
    }
    
    static func number(
        format: String? = nil,
        title: String? = nil, description: String? = nil,
        nullable: Bool? = nil,
        example: AnyJson? = nil,
        minimum: Double? = nil,
        maximum: Double? = nil
    ) -> Self {
        .init(
            type: .number,
            format: format,
            title: title, description: description,
            nullable: nullable,
            enum: nil,
            maxItems: nil, minItems: nil,
            properties: nil, required: nil,
            minProperties: nil, maxProperties: nil,
            minLength: nil, maxLength: nil,
            pattern: nil,
            example: example,
            anyOf: nil,
            propertyOrdering: nil,
            items: nil,
            minimum: minimum, maximum: maximum
        )
    }
    
    static func integer(
        format: String? = nil,
        title: String? = nil, description: String? = nil,
        nullable: Bool? = nil,
        example: AnyJson? = nil,
        minimum: Double? = nil, maximum: Double? = nil
    ) -> Self {
        .init(
            type: .integer,
            format: format,
            title: title, description: description,
            nullable: nullable,
            enum: nil,
            maxItems: nil, minItems: nil,
            properties: nil, required: nil,
            minProperties: nil, maxProperties: nil,
            minLength: nil, maxLength: nil,
            pattern: nil,
            example: example,
            anyOf: nil,
            propertyOrdering: nil,
            items: nil,
            minimum: minimum, maximum: maximum
        )
    }
    
    static func boolean(
        title: String? = nil, description: String? = nil,
        nullable: Bool? = nil,
        example: AnyJson? = nil
    ) -> Self {
        .init(
            type: .boolean,
            format: nil,
            title: title, description: description,
            nullable: nullable,
            enum: nil,
            maxItems: nil, minItems: nil,
            properties: nil, required: nil,
            minProperties: nil, maxProperties: nil,
            minLength: nil, maxLength: nil,
            pattern: nil,
            example: example,
            anyOf: nil,
            propertyOrdering: nil,
            items: nil,
            minimum: nil, maximum: nil
        )
    }
    
    static func array(
        title: String? = nil, description: String? = nil,
        nullable: Bool? = nil,
        maxItems: String? = nil, minItems: String? = nil,
        example: AnyJson? = nil,
        items: Schema? = nil
    ) -> Self {
        .init(
            type: .array,
            format: nil,
            title: title, description: description,
            nullable: nullable,
            enum: nil,
            maxItems: maxItems, minItems: minItems,
            properties: nil, required: nil,
            minProperties: nil, maxProperties: nil,
            minLength: nil, maxLength: nil,
            pattern: nil,
            example: example,
            anyOf: nil,
            propertyOrdering: nil,
            items: .init(swiftOptional: items),
            minimum: nil, maximum: nil
        )
    }
    
    static func object(
        title: String? = nil, description: String? = nil,
        nullable: Bool? = nil,
        properties: [String: Schema]? = nil, required: [String]? = nil,
        minProperties: String? = nil, maxProperties: String? = nil,
        example: AnyJson? = nil,
        propertyOrdering: [String]? = nil
    ) -> Self {
        .init(
            type: .object,
            format: nil,
            title: title, description: description,
            nullable: nullable,
            enum: nil,
            maxItems: nil, minItems: nil,
            properties: properties, required: required,
            minProperties: minProperties, maxProperties: maxProperties,
            minLength: nil, maxLength: nil,
            pattern: nil,
            example: example,
            anyOf: nil,
            propertyOrdering: propertyOrdering,
            items: nil,
            minimum: nil, maximum: nil
        )
    }
    
    static func anyOf(
        title: String? = nil, description: String? = nil,
        nullable: Bool? = nil,
        example: AnyJson? = nil,
        schemas: [Schema]
    ) -> Self {
        .init(
            type: .unspecified,
            format: nil,
            title: title, description: description,
            nullable: nullable,
            enum: nil,
            maxItems: nil, minItems: nil,
            properties: nil, required: nil,
            minProperties: nil, maxProperties: nil,
            minLength: nil, maxLength: nil,
            pattern: nil,
            example: example,
            anyOf: schemas,
            propertyOrdering: nil,
            items: nil,
            minimum: nil, maximum: nil
        )
    }
}
