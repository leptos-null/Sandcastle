//
//  SysctlFunctionProvider.swift
//  Sandcastle
//
//  Created by Leptos on 3/12/26.
//

import Foundation
import Gemini

class SysctlFunctionProvider: LiveSessionManager.Tools.FunctionProvider {
    let functionDeclarations: [FunctionDeclaration] = [
        .init(
            name: "sysctlbyname", description: "Retrieves system information. Wrapper for `sysctlbyname(3)`",
            behavior: nil, parameters: .object(properties: [
                "name": .string(example: "hw.machine")
            ]), parametersJsonSchema: nil, response: nil, responseJsonSchema: nil
        )
    ]
    
    init() {
    }
    
    private func handleSysctlbyname(parameters: ProtobufStructContainer) -> Protobuf.Struct {
        let entryName: String
        do {
            entryName = try parameters.value(for: "name").string()
        } catch {
            return [
                "error": .string(error.localizedDescription)
            ]
        }
        
        do {
            // it would be nice if we could use the format information, however access to those seem to be restricted on iOS
            let rawBytes: [UInt8] = try SystemInformation.object(for: entryName)
            
            let stringRepresentation: String? = String(validatingNullTerminatedUTF8: rawBytes)
            
            // represent as a Double so we only have to do 1 conversion per type
            let signedIntegerRepresentation: Double?
            let unsignedIntegerRepresentation: Double?
            
            switch rawBytes.count {
            case 1:
                signedIntegerRepresentation = .init(rawBytes.unsafeBitcast(to: Int8.self))
                unsignedIntegerRepresentation = .init(rawBytes.unsafeBitcast(to: UInt8.self))
            case 2:
                signedIntegerRepresentation = .init(rawBytes.unsafeBitcast(to: Int16.self))
                unsignedIntegerRepresentation = .init(rawBytes.unsafeBitcast(to: UInt16.self))
            case 4:
                signedIntegerRepresentation = .init(rawBytes.unsafeBitcast(to: Int32.self))
                unsignedIntegerRepresentation = .init(rawBytes.unsafeBitcast(to: UInt32.self))
            case 8:
                signedIntegerRepresentation = .init(rawBytes.unsafeBitcast(to: Int64.self))
                unsignedIntegerRepresentation = .init(rawBytes.unsafeBitcast(to: UInt64.self))
            default:
                signedIntegerRepresentation = nil
                unsignedIntegerRepresentation = nil
            }
            
            var build: Protobuf.Struct = [:]
            if let stringRepresentation {
                build["string"] = .string(stringRepresentation)
            }
            if let signedIntegerRepresentation {
                build["signed_integer"] = .number(signedIntegerRepresentation)
            }
            if let unsignedIntegerRepresentation {
                build["unsigned_integer"] = .number(unsignedIntegerRepresentation)
            }
            return build
        } catch {
            return [
                "error": .string(error.localizedDescription)
            ]
        }
    }
    
    func handleFunctionCall(name: String, parameters: ProtobufStructContainer) async -> LiveSessionManager.Tools.ThinnedFunctionResponse {
        let response: Protobuf.Struct = switch name {
        case "sysctlbyname":
            handleSysctlbyname(parameters: parameters)
        default:
            [
                "error": .string("unknown function")
            ]
        }
        return .init(response: response)
    }
}

private extension Array {
    func unsafeBitcast<T>(to type: T.Type = T.self) -> T {
        precondition(MemoryLayout<Element>.stride * self.count == MemoryLayout<T>.size)
        
        return self.withUnsafeBytes { (bufferPointer: UnsafeRawBufferPointer) in
            bufferPointer.load(as: type)
        }
    }
}

private extension String {
    init?<S: Sequence>(validatingNullTerminatedUTF8 codeUnits: S) where S.Element == UTF8.CodeUnit {
        let prefixUnits = codeUnits.prefix { codeUnit in
            codeUnit != 0 // null terminator
        }
        self.init(validating: prefixUnits, as: UTF8.self)
    }
}
