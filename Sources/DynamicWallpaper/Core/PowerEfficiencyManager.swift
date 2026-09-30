import AppKit
import Combine
import IOKit.ps

public class PowerEfficiencyManager {
    public static let shared = PowerEfficiencyManager()
    
    public var onShouldPauseChanged: ((Bool) -> Void)?
    
    private var isBatteryPaused: Bool = false
    private var isFullscreenPaused: Bool = false
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe Space (Virtual Desktop) transitions
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .sink { [weak self] _ in
                self?.checkFullscreenState()
            }
            .store(in: &cancellables)
        
        // Observe app activation (user switched to another app)
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .sink { [weak self] _ in
                self?.checkFullscreenState()
            }
            .store(in: &cancellables)
        
        // Periodic check for power source (battery vs AC adapter)
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkPowerState()
        }
    }
    
    public func checkPowerState() {
        guard AppSettings.shared.pauseOnBattery else {
            if isBatteryPaused {
                isBatteryPaused = false
                evaluateState()
            }
            return
        }
        
        // Check power source via IOKit
        let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] ?? []
        
        var onBattery = false
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
                if let powerSourceState = description[kIOPSPowerSourceStateKey] as? String,
                   powerSourceState == kIOPSBatteryPowerValue {
                    onBattery = true
                    break
                }
            }
        }
        
        if onBattery != isBatteryPaused {
            isBatteryPaused = onBattery
            evaluateState()
        }
    }
    
    public func checkFullscreenState() {
        guard AppSettings.shared.pauseOnFullscreen else {
            if isFullscreenPaused {
                isFullscreenPaused = false
                evaluateState()
            }
            return
        }
        
        // Check if frontmost application has fullscreen window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            
            var isFullscreen = false
            if let frontApp = NSWorkspace.shared.frontmostApplication,
               frontApp.bundleIdentifier != Bundle.main.bundleIdentifier {
                
                // Inspect window list using CGWindowListCopyWindowInfo
                let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
                if let windowListInfo = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] {
                    for windowInfo in windowListInfo {
                        guard let pid = windowInfo[kCGWindowOwnerPID as String] as? pid_t,
                              pid == frontApp.processIdentifier else { continue }
                        
                        if let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
                           let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) {
                            
                            // Check if bounds cover any screen fully
                            for screen in NSScreen.screens {
                                if bounds.width >= screen.frame.width && bounds.height >= screen.frame.height {
                                    isFullscreen = true
                                    break
                                }
                            }
                        }
                        if isFullscreen { break }
                    }
                }
            }
            
            if isFullscreen != self.isFullscreenPaused {
                self.isFullscreenPaused = isFullscreen
                self.evaluateState()
            }
        }
    }
    
    private func evaluateState() {
        let shouldPause = isBatteryPaused || isFullscreenPaused
        onShouldPauseChanged?(shouldPause)
    }
    
    deinit {
        timer?.invalidate()
    }
}
