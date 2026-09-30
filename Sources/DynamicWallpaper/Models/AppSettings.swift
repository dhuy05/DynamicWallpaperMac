import Foundation
import Combine
import SwiftUI

public class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    
    @Published public var isMuted: Bool {
        didSet { defaults.set(isMuted, forKey: "isMuted") }
    }
    
    @Published public var volume: Float {
        didSet { defaults.set(volume, forKey: "volume") }
    }
    
    @Published public var playbackRate: Float {
        didSet { defaults.set(playbackRate, forKey: "playbackRate") }
    }
    
    @Published public var videoGravity: String {
        didSet { defaults.set(videoGravity, forKey: "videoGravity") }
    }
    
    @Published public var pauseOnBattery: Bool {
        didSet { defaults.set(pauseOnBattery, forKey: "pauseOnBattery") }
    }
    
    @Published public var pauseOnFullscreen: Bool {
        didSet { defaults.set(pauseOnFullscreen, forKey: "pauseOnFullscreen") }
    }
    
    @Published public var showInDock: Bool {
        didSet { defaults.set(showInDock, forKey: "showInDock") }
    }
    
    @Published public var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: "launchAtLogin") }
    }
    
    @Published public var selectedWallpaperId: UUID? {
        didSet {
            if let id = selectedWallpaperId {
                defaults.set(id.uuidString, forKey: "selectedWallpaperId")
            } else {
                defaults.removeObject(forKey: "selectedWallpaperId")
            }
        }
    }
    
    @Published public var screenWallpaperMap: [String: String] {
        didSet { defaults.set(screenWallpaperMap, forKey: "screenWallpaperMap") }
    }
    
    @Published public var isPlaying: Bool = true
    
    private init() {
        self.isMuted = defaults.object(forKey: "isMuted") as? Bool ?? true
        self.volume = defaults.object(forKey: "volume") as? Float ?? 0.0
        self.playbackRate = defaults.object(forKey: "playbackRate") as? Float ?? 1.0
        self.videoGravity = defaults.string(forKey: "videoGravity") ?? "resizeAspectFill"
        self.pauseOnBattery = defaults.object(forKey: "pauseOnBattery") as? Bool ?? false
        self.pauseOnFullscreen = defaults.object(forKey: "pauseOnFullscreen") as? Bool ?? true
        self.showInDock = defaults.object(forKey: "showInDock") as? Bool ?? true
        self.launchAtLogin = defaults.object(forKey: "launchAtLogin") as? Bool ?? false
        
        if let idString = defaults.string(forKey: "selectedWallpaperId"), let uuid = UUID(uuidString: idString) {
            self.selectedWallpaperId = uuid
        } else {
            self.selectedWallpaperId = nil
        }
        
        self.screenWallpaperMap = defaults.dictionary(forKey: "screenWallpaperMap") as? [String: String] ?? [:]
    }
}
