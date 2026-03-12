//
//  SystemInformation.swift
//  Sandcastle
//
//  Created by Leptos on 11/15/25.
//

import Foundation
import System

// modified from <https://github.com/leptos-null/Canopy/blob/539b43f50d4f426ee926484215f7c6f03dff68d7/Canopy/SystemInformation.swift>

enum SystemInformation { // namespace
}

extension SystemInformation {
    struct ObjectID: Hashable {
        let rawValue: [Int32]
    }
}

extension SystemInformation {
    struct QueryResult {
        // The amount of data copied into the buffer
        let byteCount: Int
        // All of the data available was written to the buffer
        let didWriteAll: Bool
    }
    
    @discardableResult
    static func object(for objectID: ObjectID, outputBuffer buffer: UnsafeMutableRawBufferPointer) throws(System.Errno) -> QueryResult {
        var rawID = objectID.rawValue
        let result: QueryResult = try rawID.withUnsafeMutableBufferPointer { objectIDPointer throws(System.Errno) in
            var bufferCount = buffer.count
            let result = sysctl(objectIDPointer.baseAddress, u_int(objectIDPointer.count), buffer.baseAddress, &bufferCount, nil, 0)
            let errnoCopy: System.Errno.RawValue = errno
            
            // happy path
            if result == 0 {
                return .init(byteCount: bufferCount, didWriteAll: true)
            }
            
            guard (errnoCopy == ENOMEM) else {
                throw System.Errno(rawValue: errnoCopy)
            }
            
            return .init(byteCount: bufferCount, didWriteAll: false)
        }
        return result
    }
    
    static func probeObjectSize(for objectID: ObjectID) throws(System.Errno) -> Int {
        var rawID = objectID.rawValue
        let result: Int = try rawID.withUnsafeMutableBufferPointer { objectIDPointer throws(System.Errno) in
            var bufferCount: Int = 0
            let result = sysctl(objectIDPointer.baseAddress, u_int(objectIDPointer.count), nil, &bufferCount, nil, 0)
            let errnoCopy: System.Errno.RawValue = errno
            
            guard (result == 0) else {
                throw System.Errno(rawValue: errnoCopy)
            }
            return bufferCount
        }
        return result
    }
    
    static func object<T>(for objectID: ObjectID, maxCount: Int) throws(System.Errno) -> [T] where T: ExpressibleByIntegerLiteral {
        var array: [T] = .init(repeating: 0, count: maxCount)
        
        let boxed: Result<QueryResult, System.Errno> = array.withUnsafeMutableBytes { bytes in
            Result { () throws(System.Errno) in
                try self.object(for: objectID, outputBuffer: bytes)
            }
        }
        let result = try boxed.get()
        
        let (quotient, remainder) = result.byteCount.quotientAndRemainder(dividingBy: MemoryLayout<T>.size)
        
        var targetCount: Int = quotient
        if (remainder != 0) {
            targetCount += 1 // fault
        }
        
        guard result.didWriteAll else {
            throw System.Errno(rawValue: ENOMEM)
        }
        array.removeLast(array.count - targetCount)
        return array
    }
    
    static func object<T>(for objectID: ObjectID) throws(System.Errno) -> [T] where T: ExpressibleByIntegerLiteral {
        let probe = try self.probeObjectSize(for: objectID)
        
        let (quotient, remainder) = probe.quotientAndRemainder(dividingBy: MemoryLayout<T>.size)
        var targetCount: Int = quotient
        if (remainder != 0) {
            targetCount += 1 // fault
        }
        
        return try self.object(for: objectID, maxCount: targetCount)
    }
}

extension SystemInformation {
    // ideally this should `throws(System.Errno)`, however `Array.init(unsafeUninitializedCapacity:initializingWith:)`
    // doesn't provide a strongly-typed `rethrows`, so the type information is lost
    static func nameToObjectID(_ name: String) throws -> ObjectID {
        let rawObjectID: [Int32] = try name.withCString(encodedAs: Unicode.ASCII.self) { cName in
            try .init(unsafeUninitializedCapacity: Int(CTL_MAXNAME)) { buffer, initializedCount in
                var rawCount: Int = buffer.count
                let result = sysctlnametomib(cName, buffer.baseAddress, &rawCount)
                let errnoCopy: System.Errno.RawValue = errno
                
                guard result == 0 else {
                    throw System.Errno(rawValue: errnoCopy)
                }
                initializedCount = rawCount
            }
        }
        return .init(rawValue: rawObjectID)
    }
    
    static func object<T>(for name: String) throws -> [T] where T: ExpressibleByIntegerLiteral {
        let objectID = try self.nameToObjectID(name)
        return try self.object(for: objectID)
    }
}

extension SystemInformation.ObjectID: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue.lexicographicallyPrecedes(rhs.rawValue)
    }
}
