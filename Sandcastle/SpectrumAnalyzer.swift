//
//  SpectrumAnalyzer.swift
//  Sandcastle
//
//  Created by Leptos on 2/26/26.
//

import Foundation
import AVFoundation
import Accelerate
import OSLog

@MainActor
@Observable
final class SpectrumAnalyzer {
    private static let logger = Logger(subsystem: "SpectrumAnalyzer", category: "Audio")
    
    private static let log2n: Int = 10
    static let fftSize: Int = 1 << log2n
    static let binCount: Int = fftSize / 2
    
    /// dB magnitude for each frequency bin
    ///
    /// Each element is in `[-160, 0]`
    private(set) var magnitudes: [Float] = Array(repeating: -160, count: binCount)
    
    private let fft = vDSP.FFT(log2n: vDSP_Length(log2n), radix: .radix2, ofType: DSPSplitComplex.self)
    private let hannWindow: [Float] = vDSP.window(
        ofType: Float.self, usingSequence: .hanningDenormalized,
        count: fftSize, isHalfWindow: false
    )
    
    @ObservationIgnored
    private var sampleBuffer: [Float] = []
    
    func append(buffer: AVAudioPCMBuffer) {
        let bufferFormat = buffer.format
        guard bufferFormat.channelCount == 1 else {
            Self.logger.error("\(#function) requires mono audio")
            return
        }
        guard bufferFormat.sampleRate.distance(to: 16_000).magnitude < 2 else {
            Self.logger.error("\(#function) requires 16kHz audio")
            return
        }
        guard let channelData = buffer.int16ChannelData else {
            Self.logger.error("\(#function) requires pcmFormatInt16 audio")
            return
        }
        
        let frameLength = Int(buffer.frameLength)
        
        let floatSamples: [Float] = .init(unsafeUninitializedCapacity: frameLength) { buffer, initializedCount in
            let channelBuffer = UnsafeBufferPointer(start: channelData[0], count: frameLength)
            vDSP.convertElements(of: channelBuffer, to: &buffer)
            initializedCount = frameLength
        }
        
        let normalizationScale: Float = 1 / Float(Int16.max)
        let normalizedSamples: [Float] = vDSP.multiply(normalizationScale, floatSamples)
        
        sampleBuffer.append(contentsOf: normalizedSamples)
        
        // since `processWindow` smoothes the data over time, we need to send all data
        while sampleBuffer.count >= Self.fftSize {
            self.processWindow(sampleBuffer.prefix(Self.fftSize))
            sampleBuffer.removeFirst(Self.fftSize)
        }
    }
    
    private func processWindow<T: AccelerateBuffer>(_ samples: T) where T.Element == Float {
        guard let fft else {
            Self.logger.fault("Unable to create fft")
            return
        }
        
        // much of this code is based on <https://developer.apple.com/documentation/accelerate/reducing-spectral-leakage-with-windowing>
        
        let windowed = vDSP.multiply(samples, hannWindow)
        
        var realPart = [Float](repeating: 0, count: Self.binCount)
        var imagPart = [Float](repeating: 0, count: Self.binCount)
        
        realPart.withUnsafeMutableBufferPointer { realBuf in
            imagPart.withUnsafeMutableBufferPointer { imagBuf in
                var splitComplex = DSPSplitComplex(
                    realp: realBuf.baseAddress!,
                    imagp: imagBuf.baseAddress!
                )
                windowed.withUnsafeBytes { (windowedBytes: UnsafeRawBufferPointer) in
                    let windowedBase: UnsafeRawPointer = windowedBytes.baseAddress!
                    // the Swift overlay is `vDSP.convert(interleavedComplexVector:toSplitComplexVector:)`
                    // however that requires us to copy the `windowedBytes`, which is unnecessary
                    vDSP_ctoz(
                        windowedBase.assumingMemoryBound(to: DSPComplex.self), 2,
                        &splitComplex, 1,
                        vDSP_Length(Self.binCount)
                    )
                }
                
                fft.forward(input: splitComplex, output: &splitComplex)
                
                // compute squared magnitudes (power)
                var squaredMagnitudes: [Float] = .init(unsafeUninitializedCapacity: Self.binCount) { buffer, initializedCount in
                    vDSP.squareMagnitudes(splitComplex, result: &buffer) // vDSP_zvmags
                    initializedCount = Self.binCount
                }
                
                let magnitudeNormalize = Float(Self.binCount)
                let scaleFactor: Float = 1 / (magnitudeNormalize * magnitudeNormalize) // square since the vector is squared
                vDSP.multiply(scaleFactor, squaredMagnitudes, result: &squaredMagnitudes)
                
                let newMagnitudes: [Float] = .init(unsafeUninitializedCapacity: Self.binCount) { buffer, initializedCount in
                    vDSP.convert(power: squaredMagnitudes, toDecibels: &buffer, zeroReference: 1)
                    initializedCount = Self.binCount
                }
                
                // exponential moving average with separate attack/release coefficients,
                // so levels rise quickly but decay slowly - similar to a VU meter
                let attack: Float = 0.625
                let release: Float = 0.375
                magnitudes = zip(newMagnitudes, magnitudes)
                    .map { newMagnitude, smooth in
                        let magnitude = max(newMagnitude, -160)
                        let alpha = (magnitude > smooth) ? attack : release
                        return alpha * magnitude + (1 - alpha) * smooth
                    }
            }
        }
    }
}
