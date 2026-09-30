import AppKit
import AVFoundation
import Combine

public class WallpaperEngine: ObservableObject {
    public static let shared = WallpaperEngine()
    
    @Published public private(set) var activeWindows: [String: DesktopWindow] = [:]
    @Published public private(set) var currentWallpaper: WallpaperItem?
    @Published public var isEnginePlaying: Bool = true
    
    private var powerEfficiencyPaused: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Screen change notifications
        ScreenObserver.shared.onScreensChanged = { [weak self] _ in
            self?.refreshScreens()
        }
        
        // Power efficiency (battery/fullscreen) auto-pause
        PowerEfficiencyManager.shared.onShouldPauseChanged = { [weak self] shouldPause in
            guard let self = self else { return }
            self.powerEfficiencyPaused = shouldPause
            if shouldPause {
                self.pauseAll()
            } else if AppSettings.shared.isPlaying {
                self.resumeAll()
            }
        }
        
        // React to setting changes
        let settings = AppSettings.shared
        settings.$isMuted
            .sink { [weak self] muted in
                self?.activeWindows.values.forEach { $0.playerController?.isMuted = muted }
            }
            .store(in: &cancellables)
        
        settings.$volume
            .sink { [weak self] vol in
                self?.activeWindows.values.forEach { $0.playerController?.currentVolume = vol }
            }
            .store(in: &cancellables)
            
        settings.$playbackRate
            .sink { [weak self] rate in
                self?.activeWindows.values.forEach { $0.playerController?.playbackRate = rate }
            }
            .store(in: &cancellables)
            
        settings.$videoGravity
            .sink { [weak self] gravity in
                self?.activeWindows.values.forEach { $0.playerController?.setGravity(gravity) }
            }
            .store(in: &cancellables)
    }
    
    public func start(with defaultWallpaper: WallpaperItem?) {
        self.currentWallpaper = defaultWallpaper
        refreshScreens()
    }
    
    public func setWallpaper(_ item: WallpaperItem, forScreen screenIdentifier: String? = nil) {
        self.currentWallpaper = item
        AppSettings.shared.selectedWallpaperId = item.id
        
        if activeWindows.isEmpty {
            refreshScreens()
        }
        
        if let targetScreenId = screenIdentifier {
            // Apply to specific screen
            AppSettings.shared.screenWallpaperMap[targetScreenId] = item.id.uuidString
            if let window = activeWindows[targetScreenId] {
                applyWallpaper(item, to: window)
            }
        } else {
            // Apply to all screens
            for (_, window) in activeWindows {
                applyWallpaper(item, to: window)
            }
        }
    }
    
    private func applyWallpaper(_ item: WallpaperItem, to window: DesktopWindow) {
        let playerController = window.playerController ?? VideoPlayerController()
        playerController.isMuted = AppSettings.shared.isMuted
        playerController.currentVolume = AppSettings.shared.volume
        playerController.playbackRate = AppSettings.shared.playbackRate
        playerController.setGravity(AppSettings.shared.videoGravity)
        
        window.attachPlayerController(playerController)
        playerController.loadVideo(url: item.fileURL, autoPlay: AppSettings.shared.isPlaying && !powerEfficiencyPaused)
    }
    
    public func togglePlayback() {
        if isEnginePlaying {
            pauseAll()
            AppSettings.shared.isPlaying = false
        } else {
            resumeAll()
            AppSettings.shared.isPlaying = true
        }
    }
    
    public func pauseAll() {
        activeWindows.values.forEach { $0.playerController?.pause() }
        isEnginePlaying = false
    }
    
    public func resumeAll() {
        guard !powerEfficiencyPaused else { return }
        activeWindows.values.forEach { $0.playerController?.play() }
        isEnginePlaying = true
    }
    
    public func refreshScreens() {
        let screens = NSScreen.screens
        var newWindows: [String: DesktopWindow] = [:]
        
        for screen in screens {
            let screenId = screenIdentifier(for: screen)
            
            if let existingWindow = activeWindows[screenId] {
                existingWindow.updateFrame()
                newWindows[screenId] = existingWindow
            } else {
                let newWindow = DesktopWindow(screen: screen)
                newWindows[screenId] = newWindow
            }
        }
        
        // Close windows for disconnected screens
        for (screenId, window) in activeWindows {
            if newWindows[screenId] == nil {
                window.playerController?.stop()
                window.close()
            }
        }
        
        self.activeWindows = newWindows
        
        // Apply wallpaper to windows
        if let wallpaper = currentWallpaper {
            for (_, window) in self.activeWindows {
                applyWallpaper(wallpaper, to: window)
            }
        }
    }
    
    public func screenIdentifier(for screen: NSScreen) -> String {
        if let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            return "Display-\(number.intValue)"
        }
        return "Display-\(screen.frame.origin.x)-\(screen.frame.origin.y)"
    }
    
    public func stopAll() {
        for (_, window) in activeWindows {
            window.playerController?.stop()
            window.close()
        }
        activeWindows.removeAll()
        isEnginePlaying = false
    }
    
    deinit {
        stopAll()
    }
}
