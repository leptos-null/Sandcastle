//
//  AudioBufferConverter.swift
//  Sandcastle
//
//  Created by Leptos on 2/22/26.
//

import Foundation
@preconcurrency import AVFoundation

// Heavily based on code from
// <https://developer.apple.com/documentation/Speech/bringing-advanced-speech-to-text-capabilities-to-your-app>

actor AudioBufferConverter {
    private var underlying: AVAudioConverter?
    
    func convert(buffer: AVAudioPCMBuffer, to outputFormat: AVAudioFormat) throws -> AVAudioPCMBuffer {
        let inputFormat = buffer.format
        if inputFormat == outputFormat {
            return buffer
        }
        if underlying?.inputFormat != inputFormat || underlying?.outputFormat != outputFormat {
            underlying = AVAudioConverter(from: inputFormat, to: outputFormat)
        }
        
        guard let underlying else {
            throw Error.unsupportedConversion
        }
        let sampleRateRatio: Double = underlying.outputFormat.sampleRate / underlying.inputFormat.sampleRate
        
        let scaledInputFrameLength = Double(buffer.frameLength) * sampleRateRatio
        let outputFrameCapacity = AVAudioFrameCount(scaledInputFrameLength.rounded(.awayFromZero))
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCapacity) else {
            throw Error.failedToCreateOutputBuffer
        }
        
        var nsError: NSError?
        var didProvideBuffer: Bool = false
        
        let convertStatus = underlying.convert(to: outputBuffer, error: &nsError) { packetCount, statusPointer in
            if didProvideBuffer {
                statusPointer.pointee = .noDataNow
                return nil
            }
            didProvideBuffer = true
            statusPointer.pointee = .haveData
            return buffer
        }
        if convertStatus == .error {
            if let nsError {
                throw nsError
            }
            throw Error.unknown
        }
        return outputBuffer
    }
}

extension AudioBufferConverter {
    nonisolated enum Error: Swift.Error {
        /// The format conversion is not supported
        case unsupportedConversion
        /// The resulting `AVAudioPCMBuffer` could not be created
        case failedToCreateOutputBuffer
        /// An unknown error occurred during conversion
        case unknown
    }
}
