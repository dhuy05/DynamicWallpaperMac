import AppKit
import AVFoundation

public class ThumbnailGenerator {
    public static let shared = ThumbnailGenerator()
    
    private let cache = NSCache<NSURL, NSImage>()
    
    private init() {
        cache.countLimit = 50
    }
    
    public func generateThumbnail(for videoURL: URL, at timeSeconds: Double = 0.5) async -> NSImage? {
        if let cached = cache.object(forKey: videoURL as NSURL) {
            return cached
        }
        
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 640, height: 360)
        
        let time = CMTime(seconds: timeSeconds, preferredTimescale: 600)
        
        do {
            let cgImage = try await generator.image(at: time).image
            let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            cache.setObject(image, forKey: videoURL as NSURL)
            return image
        } catch {
            print("Failed to generate thumbnail for \(videoURL): \(error)")
            return nil
        }
    }
    
    public func saveThumbnail(image: NSImage, to destinationURL: URL) -> Bool {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return false
        }
        
        do {
            try pngData.write(to: destinationURL)
            return true
        } catch {
            print("Failed to save thumbnail: \(error)")
            return false
        }
    }
}
