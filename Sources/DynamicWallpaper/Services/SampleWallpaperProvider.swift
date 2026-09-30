import AppKit
import AVFoundation
import CoreGraphics

public class SampleWallpaperProvider {
    public static let shared = SampleWallpaperProvider()
    
    public var samplesDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("DynamicWallpaper/Samples", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    public func ensureSampleWallpapers() async -> [WallpaperItem] {
        var items: [WallpaperItem] = []
        
        let samples = [
            ("Aurora Borealis", "aurora.mp4", generateAuroraFrame),
            ("Cyber Sunset Grid", "cybergrid.mp4", generateGridFrame),
            ("Liquid Cosmic Gradient", "cosmic.mp4", generateCosmicFrame)
        ]
        
        for (title, filename, renderer) in samples {
            let fileURL = samplesDirectory.appendingPathComponent(filename)
            let thumbURL = samplesDirectory.appendingPathComponent(filename.replacingOccurrences(of: ".mp4", with: "_thumb.png"))
            
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                print("Generating sample wallpaper: \(title)...")
                await createVideoFile(outputURL: fileURL, renderer: renderer)
            }
            
            // Generate thumbnail if missing
            if !FileManager.default.fileExists(atPath: thumbURL.path) {
                if let thumbImage = await ThumbnailGenerator.shared.generateThumbnail(for: fileURL, at: 0.5) {
                    _ = ThumbnailGenerator.shared.saveThumbnail(image: thumbImage, to: thumbURL)
                }
            }
            
            let item = WallpaperItem(
                title: title,
                fileURL: fileURL,
                thumbnailURL: FileManager.default.fileExists(atPath: thumbURL.path) ? thumbURL : nil,
                duration: 6.0,
                width: 1920,
                height: 1080,
                isBuiltIn: true
            )
            items.append(item)
        }
        
        return items
    }
    
    private func createVideoFile(
        outputURL: URL,
        renderer: @escaping (CGContext, CGSize, Double) -> Void
    ) async {
        let width = 1920
        let height = 1080
        let fps: Int32 = 30
        let durationSeconds: Double = 6.0
        let totalFrames = Int(durationSeconds * Double(fps))
        
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else { return }
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 6_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writerInput.expectsMediaDataInRealTime = false
        
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height
        ]
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: pixelBufferAttributes
        )
        
        if writer.canAdd(writerInput) {
            writer.add(writerInput)
        } else {
            return
        }
        
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue
        
        for frameIndex in 0..<totalFrames {
            while !writerInput.isReadyForMoreMediaData {
                try? await Task.sleep(nanoseconds: 10_000_000)
            }
            
            var pixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferCreate(
                kCFAllocatorDefault,
                width,
                height,
                kCVPixelFormatType_32ARGB,
                pixelBufferAttributes as CFDictionary,
                &pixelBuffer
            )
            
            guard status == kCVReturnSuccess, let buffer = pixelBuffer else { continue }
            
            CVPixelBufferLockBaseAddress(buffer, [])
            let pxData = CVPixelBufferGetBaseAddress(buffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
            
            if let context = CGContext(
                data: pxData,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) {
                let progress = Double(frameIndex) / Double(totalFrames)
                renderer(context, CGSize(width: width, height: height), progress)
            }
            
            CVPixelBufferUnlockBaseAddress(buffer, [])
            
            let frameTime = CMTime(value: Int64(frameIndex), timescale: fps)
            adaptor.append(buffer, withPresentationTime: frameTime)
        }
        
        writerInput.markAsFinished()
        await writer.finishWriting()
    }
    
    // 1. Aurora Borealis Renderer
    private func generateAuroraFrame(ctx: CGContext, size: CGSize, progress: Double) {
        // Deep midnight sky background
        ctx.setFillColor(red: 0.02, green: 0.03, blue: 0.08, alpha: 1.0)
        ctx.fill(CGRect(origin: .zero, size: size))
        
        // Stars
        let starCount = 80
        for i in 0..<starCount {
            let seed = Double(i) * 137.5
            let x = CGFloat(fmod(seed * 71.0, Double(size.width)))
            let y = CGFloat(fmod(seed * 97.0, Double(size.height * 0.85)) + Double(size.height * 0.15))
            let twinkle = 0.5 + 0.5 * sin(2.0 * .pi * (progress + Double(i) / Double(starCount)))
            ctx.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: CGFloat(twinkle * 0.8))
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
        }
        
        // Wavy Aurora Ribbons (teal, emerald, magenta)
        let ribbonCount = 4
        for r in 0..<ribbonCount {
            ctx.saveGState()
            let phase = progress * 2.0 * .pi + Double(r) * 1.5
            let baseY = size.height * (0.35 + CGFloat(r) * 0.12)
            
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: baseY))
            
            for x in stride(from: 0, through: Int(size.width), by: 30) {
                let xf = Double(x)
                let wave1 = sin(xf * 0.003 + phase) * 80.0
                let wave2 = cos(xf * 0.007 - phase * 0.7) * 40.0
                let y = baseY + CGFloat(wave1 + wave2)
                path.addLine(to: CGPoint(x: CGFloat(x), y: y))
            }
            
            path.addLine(to: CGPoint(x: size.width, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.closeSubpath()
            
            let rCol = r % 2 == 0 ? 0.05 : 0.4
            let gCol = r % 2 == 0 ? 0.85 : 0.2
            let bCol = r % 2 == 0 ? 0.65 : 0.9
            ctx.setFillColor(red: CGFloat(rCol), green: CGFloat(gCol), blue: CGFloat(bCol), alpha: 0.28)
            ctx.addPath(path)
            ctx.fillPath()
            ctx.restoreGState()
        }
    }
    
    // 2. Cyber Sunset Grid Renderer
    private func generateGridFrame(ctx: CGContext, size: CGSize, progress: Double) {
        // Gradient sky: Deep purple to neon orange
        let horizonY = size.height * 0.45
        let colors = [
            CGColor(red: 0.08, green: 0.02, blue: 0.18, alpha: 1.0),
            CGColor(red: 0.35, green: 0.05, blue: 0.45, alpha: 1.0),
            CGColor(red: 0.95, green: 0.25, blue: 0.35, alpha: 1.0),
            CGColor(red: 1.0, green: 0.65, blue: 0.15, alpha: 1.0)
        ] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 0.4, 0.8, 1.0]) {
            ctx.drawLinearGradient(
                gradient,
                start: CGPoint(x: size.width / 2, y: size.height),
                end: CGPoint(x: size.width / 2, y: horizonY),
                options: []
            )
        }
        
        // Glowing Neon Sun
        let sunRadius: CGFloat = 180
        let sunCenter = CGPoint(x: size.width / 2, y: horizonY + 30)
        ctx.saveGState()
        ctx.setFillColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.9)
        ctx.fillEllipse(in: CGRect(x: sunCenter.x - sunRadius, y: sunCenter.y - sunRadius, width: sunRadius * 2, height: sunRadius * 2))
        
        // Sun horizontal scanline bars
        ctx.setFillColor(red: 0.08, green: 0.02, blue: 0.18, alpha: 0.95)
        for i in 0..<8 {
            let barY = sunCenter.y - sunRadius + CGFloat(i) * 22
            let barH = CGFloat(2 + i * 2)
            ctx.fill(CGRect(x: sunCenter.x - sunRadius - 10, y: barY, width: sunRadius * 2 + 20, height: barH))
        }
        ctx.restoreGState()
        
        // Dark floor for grid
        ctx.setFillColor(red: 0.03, green: 0.01, blue: 0.08, alpha: 1.0)
        ctx.fill(CGRect(x: 0, y: 0, width: size.width, height: horizonY))
        
        // Perspective Grid Lines
        ctx.setStrokeColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 0.75)
        ctx.setLineWidth(2.0)
        
        // Vertical perspective lines converging to center horizon
        let lineCount = 28
        let vanishingPoint = CGPoint(x: size.width / 2, y: horizonY)
        for i in -lineCount...lineCount {
            let bottomX = size.width / 2 + CGFloat(i) * 75.0
            ctx.move(to: vanishingPoint)
            ctx.addLine(to: CGPoint(x: bottomX, y: 0))
            ctx.strokePath()
        }
        
        // Moving Horizontal Grid Lines
        let hLineCount = 14
        for i in 0..<hLineCount {
            let norm = (Double(i) + progress) / Double(hLineCount)
            let expFactor = pow(norm, 2.5) // perspective foreshortening
            let y = horizonY * CGFloat(1.0 - expFactor)
            let alpha = CGFloat(expFactor * 0.9)
            ctx.setStrokeColor(red: 0.95, green: 0.1, blue: 0.8, alpha: alpha)
            ctx.move(to: CGPoint(x: 0, y: y))
            ctx.addLine(to: CGPoint(x: size.width, y: y))
            ctx.strokePath()
        }
    }
    
    // 3. Liquid Cosmic Gradient Renderer
    private func generateCosmicFrame(ctx: CGContext, size: CGSize, progress: Double) {
        let t = progress * 2.0 * .pi
        
        // Dynamic centers moving in harmonious Lissajous curves
        let p1 = CGPoint(x: size.width * (0.3 + 0.2 * CGFloat(sin(t))), y: size.height * (0.4 + 0.2 * CGFloat(cos(t))))
        let p2 = CGPoint(x: size.width * (0.7 - 0.2 * CGFloat(cos(t))), y: size.height * (0.6 + 0.2 * CGFloat(sin(t))))
        let p3 = CGPoint(x: size.width * 0.5, y: size.height * (0.2 + 0.15 * CGFloat(sin(t * 2))))
        
        ctx.setFillColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)
        ctx.fill(CGRect(origin: .zero, size: size))
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // Orb 1: Radiant Sapphire Blue
        if let g1 = CGGradient(colorsSpace: colorSpace, colors: [
            CGColor(red: 0.1, green: 0.4, blue: 1.0, alpha: 0.7),
            CGColor(red: 0.1, green: 0.4, blue: 1.0, alpha: 0.0)
        ] as CFArray, locations: [0.0, 1.0]) {
            ctx.drawRadialGradient(g1, startCenter: p1, startRadius: 0, endCenter: p1, endRadius: size.width * 0.55, options: [])
        }
        
        // Orb 2: Deep Amethyst Violet
        if let g2 = CGGradient(colorsSpace: colorSpace, colors: [
            CGColor(red: 0.75, green: 0.15, blue: 0.85, alpha: 0.65),
            CGColor(red: 0.75, green: 0.15, blue: 0.85, alpha: 0.0)
        ] as CFArray, locations: [0.0, 1.0]) {
            ctx.drawRadialGradient(g2, startCenter: p2, startRadius: 0, endCenter: p2, endRadius: size.width * 0.6, options: [])
        }
        
        // Orb 3: Radiant Amber Glow
        if let g3 = CGGradient(colorsSpace: colorSpace, colors: [
            CGColor(red: 1.0, green: 0.55, blue: 0.2, alpha: 0.5),
            CGColor(red: 1.0, green: 0.55, blue: 0.2, alpha: 0.0)
        ] as CFArray, locations: [0.0, 1.0]) {
            ctx.drawRadialGradient(g3, startCenter: p3, startRadius: 0, endCenter: p3, endRadius: size.width * 0.45, options: [])
        }
    }
}
