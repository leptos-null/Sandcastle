//
//  ColorDescriptor.swift
//  Sandcastle
//
//  Created by Leptos on 4/5/26.
//

import Gemini

enum ColorDescriptor: Hashable, Sendable {
    // it may seem more favorable to pick a different representation (e.g. `[0, 1]`), however
    // these are designed to be favorable to an LLM (i.e. data it's likely seen)
    
    struct RGB: Hashable, Sendable {
        let red: UInt8 /* [0, 255] */
        let green: UInt8 /* [0, 255] */
        let blue: UInt8 /* [0, 255] */
    }
    
    struct HSB: Hashable, Sendable {
        let hue: Double /* [0, 360) */
        let saturation: Double /* [0, 100] */
        let brightness: Double /* [0, 100] */
    }
    
    enum Name: String, Hashable, Sendable, CaseIterable {
        case black
        case blue
        case brown
        case cyan
        case gray
        case green
        case indigo
        case mint
        case orange
        case pink
        case purple
        case red
        case teal
        case white
        case yellow
    }
    
    case rgb(RGB)
    case hsb(HSB)
    case name(Name)
}

extension ColorDescriptor.RGB {
    static let schema: Schema = .object(properties: [
        "red": .integer(minimum: 0, maximum: 255),
        "green": .integer(minimum: 0, maximum: 255),
        "blue": .integer(minimum: 0, maximum: 255),
    ])
    
    init(_ container: ProtobufStructContainer) throws {
        let red: UInt8 = try container.value(for: "red").integer()
        let green: UInt8 = try container.value(for: "green").integer()
        let blue: UInt8 = try container.value(for: "blue").integer()
        
        self.init(red: red, green: green, blue: blue)
    }
}

extension ColorDescriptor.HSB {
    static let schema: Schema = .object(properties: [
        "hue": .number(minimum: 0, maximum: 360),
        "saturation": .number(minimum: 0, maximum: 100),
        "brightness": .number(minimum: 0, maximum: 100),
    ])
    
    init(_ container: ProtobufStructContainer) throws {
        let hue: Double = try container.value(for: "hue").double()
        let saturation: Double = try container.value(for: "saturation").double()
        let brightness: Double = try container.value(for: "brightness").double()
        
        self.init(hue: hue, saturation: saturation, brightness: brightness)
    }
}

extension ColorDescriptor.Name {
    static let schema: Schema = .string(format: "enum", enum: ColorDescriptor.Name.allCases.map(\.rawValue))
}

extension ColorDescriptor {
    static let schema: Schema = .anyOf(schemas: [
        .object(properties: ["rgb": RGB.schema]),
        .object(properties: ["hsb": HSB.schema]),
        .object(properties: ["name": Name.schema]),
    ])
    
    init(_ container: ProtobufStructContainer) throws {
        let rgbCandidate: RGB? = try container.value(for: "rgb").accessIfPresent { valueContainer in
            let childContainer = try valueContainer.dictionary()
            return try RGB(childContainer)
        }
        if let rgbCandidate {
            self = .rgb(rgbCandidate)
            return
        }
        
        let hsbCandidate: HSB? = try container.value(for: "hsb").accessIfPresent { valueContainer in
            let childContainer = try valueContainer.dictionary()
            return try HSB(childContainer)
        }
        if let hsbCandidate {
            self = .hsb(hsbCandidate)
            return
        }
        
        let nameCandidate: Name? = try container.value(for: "name").accessIfPresent { valueContainer in
            try valueContainer.rawRepresentable()
        }
        if let nameCandidate {
            self = .name(nameCandidate)
            return
        }
        // not the most accurate representation of the error, but it should produce the error message we're looking for
        throw ProtobufValueReadError(expected: .dictionary, found: .dictionary(container.underlying), path: container.path)
    }
    
    init(_ container: ProtobufValueContainer) throws {
        let structContainer = try container.dictionary()
        try self.init(structContainer)
    }
}
