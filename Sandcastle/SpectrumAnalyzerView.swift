//
//  SpectrumAnalyzerView.swift
//  Sandcastle
//
//  Created by Leptos on 2/26/26.
//

import SwiftUI
import Accelerate

struct SpectrumAnalyzerView: View {
    let spectrumAnalyzer: SpectrumAnalyzer
    let shading: GraphicsContext.Shading
    
    var body: some View {
        Canvas { context, size in
            let magnitudes = spectrumAnalyzer.magnitudes
            
            let targetBinCount: CGFloat = 12 // seems to look pretty good
            let factor: Int = Int(CGFloat(magnitudes.count) / targetBinCount)
            
            let resampled: [Float]
            if factor > 1 {
                let baseFilterFactor: Float = 1.0 / Float(factor)
                let filter: [Float] = .init(repeating: baseFilterFactor, count: factor)
                resampled = vDSP.downsample(magnitudes, decimationFactor: factor, filter: filter)
            } else {
                resampled = magnitudes
            }
            
            guard resampled.count > 1 else { return }
            
            let step: CGFloat = size.width / CGFloat(resampled.count - 1)
            let points: [CGPoint] = zip(stride(from: 0, through: size.width, by: step), resampled).map { x, magnitude in
                let barHeight: CGFloat = max(0, min(CGFloat(magnitude + 160), size.height))
                // y = 0 is the top; flip so a higher strength is closer to the top
                return CGPoint(x: x, y: size.height - barHeight)
            }
            let path = Path { path in
                
                func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
                    CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
                }
                
                // points.count == resampled.count, and we already check `resampled.count` above,
                // so this should be safe
                path.move(to: points[0])
                path.addLine(to: midpoint(points[0], points[1]))
                for pointIndex in stride(from: points.startIndex + 1, to: points.endIndex - 1, by: 1) {
                    let leadingPoint = points[pointIndex + 0]
                    let trailingPoint = points[pointIndex + 1]
                    path.addQuadCurve(
                        to: midpoint(leadingPoint, trailingPoint),
                        control: leadingPoint
                    )
                }
                path.addLine(to: points[points.count - 1])
                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.addLine(to: CGPoint(x: 0, y: size.height))
                path.closeSubpath()
            }
            context.fill(path, with: shading)
        }
        .frame(height: 120)
    }
}
