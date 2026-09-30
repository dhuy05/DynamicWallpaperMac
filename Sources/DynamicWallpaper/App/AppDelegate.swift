import AppKit
import SwiftUI

public class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    public static var shared: AppDelegate!
    
    public var mainWindow: NSWindow?
    
    public override init() {
        super.init()
        AppDelegate.shared = self
    }
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Start Desktop Engine
        WallpaperEngine.shared.refreshScreens()
        
        // 2. Load library & apply active wallpaper
        WallpaperLibraryStore.shared.loadLibrary()
        
        // 3. Open Studio window on launch with Dock icon so user can configure
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.openMainWindow()
        }
    }
    
    public func openMainWindow() {
        // Show in Dock while user is setting / configuring
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }
        
        let contentView = MainWindowView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("DynamicWallpaperStudioWindow")
        window.title = "Dynamic Wallpaper Studio"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        
        self.mainWindow = window
    }
    
    public func closeMainWindow() {
        mainWindow?.close()
        // Window delegate windowWillClose will automatically hide app from Dock
    }
    
    public func windowWillClose(_ notification: Notification) {
        // As requested: Once setting is finished / window closed, hide from Dock and run only in Menu Bar!
        NSApp.setActivationPolicy(.accessory)
    }
    
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openMainWindow()
        return true
    }
}
