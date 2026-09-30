import AppKit
import AVFoundation
import Combine

public class WallpaperLibraryStore: ObservableObject {
    public static let shared = WallpaperLibraryStore()
    
    @Published public var wallpapers: [WallpaperItem] = []
    @Published public var isLoading: Bool = false
    
    private var libraryFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("DynamicWallpaper", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("library.json")
    }
    
    private init() {
        loadLibrary()
    }
    
    public func loadLibrary() {
        isLoading = true
        
        Task { @MainActor in
            // 1. Ensure built-in samples exist
            let samples = await SampleWallpaperProvider.shared.ensureSampleWallpapers()
            
            // 2. Load custom wallpapers from JSON
            var savedCustom: [WallpaperItem] = []
            if let data = try? Data(contentsOf: libraryFileURL),
               let decoded = try? JSONDecoder().decode([WallpaperItem].self, from: data) {
                // Filter out files that no longer exist
                savedCustom = decoded.filter { FileManager.default.fileExists(atPath: $0.fileURL.path) }
            }
            
            self.wallpapers = samples + savedCustom
            self.isLoading = false
            
            // If user previously selected a wallpaper, apply it!
            if let savedId = AppSettings.shared.selectedWallpaperId,
               let current = self.wallpapers.first(where: { $0.id == savedId }) {
                WallpaperEngine.shared.setWallpaper(current)
            } else if let lastCustom = savedCustom.last {
                WallpaperEngine.shared.setWallpaper(lastCustom)
            } else if let first = self.wallpapers.first {
                WallpaperEngine.shared.setWallpaper(first)
            }
        }
    }
    
    public func importVideo(from sourceURL: URL) async -> WallpaperItem? {
        let asset = AVURLAsset(url: sourceURL)
        
        // Extract duration
        var durationSeconds: Double = 0
        if let duration = try? await asset.load(.duration) {
            durationSeconds = CMTimeGetSeconds(duration)
        }
        
        // Extract dimensions
        var width = 1920
        var height = 1080
        if let tracks = try? await asset.loadTracks(withMediaType: .video), let track = tracks.first {
            if let naturalSize = try? await track.load(.naturalSize) {
                width = Int(naturalSize.width)
                height = Int(naturalSize.height)
            }
        }
        
        let title = sourceURL.deletingPathExtension().lastPathComponent
        
        // Copy to App Support so it persists even if source is deleted/moved
        let customDir = SampleWallpaperProvider.shared.samplesDirectory.appendingPathComponent("Custom", isDirectory: true)
        try? FileManager.default.createDirectory(at: customDir, withIntermediateDirectories: true)
        
        let destURL = customDir.appendingPathComponent("\(UUID().uuidString)_\(sourceURL.lastPathComponent)")
        let thumbURL = customDir.appendingPathComponent("\(UUID().uuidString)_thumb.png")
        
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
        } catch {
            print("Failed to copy video: \(error)")
            return nil
        }
        
        // Generate thumbnail
        if let thumbImage = await ThumbnailGenerator.shared.generateThumbnail(for: destURL, at: min(1.0, durationSeconds / 2)) {
            _ = ThumbnailGenerator.shared.saveThumbnail(image: thumbImage, to: thumbURL)
        }
        
        let newItem = WallpaperItem(
            title: title,
            fileURL: destURL,
            thumbnailURL: FileManager.default.fileExists(atPath: thumbURL.path) ? thumbURL : nil,
            duration: durationSeconds,
            width: width,
            height: height,
            isBuiltIn: false
        )
        
        await MainActor.run {
            self.wallpapers.append(newItem)
            self.saveCustomLibrary()
        }
        
        return newItem
    }
    
    public func removeWallpaper(_ item: WallpaperItem) {
        guard !item.isBuiltIn else { return } // Don't delete built-in presets
        
        wallpapers.removeAll { $0.id == item.id }
        try? FileManager.default.removeItem(at: item.fileURL)
        if let thumb = item.thumbnailURL {
            try? FileManager.default.removeItem(at: thumb)
        }
        saveCustomLibrary()
    }
    
    private func saveCustomLibrary() {
        let customOnly = wallpapers.filter { !$0.isBuiltIn }
        if let data = try? JSONEncoder().encode(customOnly) {
            try? data.write(to: libraryFileURL)
        }
    }
}
