import SwiftUI
import AppKit

@main
struct DynamicWallpaperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            PreferencesView()
        }
        
        // Menu Bar Companion
        MenuBarExtra("Dynamic Wallpaper", systemImage: "sparkles.tv") {
            MenuBarExtraView(
                onOpenGallery: {
                    AppDelegate.shared.openMainWindow()
                },
                onOpenPreferences: {
                    AppDelegate.shared.openMainWindow()
                }
            )
        }
        .menuBarExtraStyle(.window)
    }
}
