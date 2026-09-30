import SwiftUI
import AppKit

public struct MenuBarExtraView: View {
    @ObservedObject var engine = WallpaperEngine.shared
    @ObservedObject var library = WallpaperLibraryStore.shared
    @ObservedObject var settings = AppSettings.shared
    
    public var onOpenGallery: () -> Void
    public var onOpenPreferences: () -> Void
    
    public init(onOpenGallery: @escaping () -> Void, onOpenPreferences: @escaping () -> Void) {
        self.onOpenGallery = onOpenGallery
        self.onOpenPreferences = onOpenPreferences
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Current Wallpaper Info
            if let current = engine.currentWallpaper {
                HStack(spacing: 10) {
                    if let thumb = current.thumbnailURL, let img = NSImage(contentsOf: thumb) {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 32)
                            .cornerRadius(6)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(current.title)
                            .font(.system(size: 13, weight: .bold))
                            .lineLimit(1)
                        Text(current.resolutionText)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            
            Divider()
            
            // Playback controls
            HStack(spacing: 12) {
                Button(action: {
                    engine.togglePlayback()
                }) {
                    Label(
                        engine.isEnginePlaying ? "Tạm dừng" : "Phát",
                        systemImage: engine.isEnginePlaying ? "pause.fill" : "play.fill"
                    )
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    settings.isMuted.toggle()
                }) {
                    Image(systemName: settings.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                }
                .buttonStyle(.bordered)
                
                Button(action: selectNextWallpaper) {
                    Image(systemName: "forward.fill")
                }
                .buttonStyle(.bordered)
                .help("Hình nền tiếp theo")
            }
            
            Divider()
            
            // Quick Wallpaper switcher list
            Text("Chuyển đổi nhanh")
                .font(.caption.bold())
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(library.wallpapers.prefix(4)) { item in
                    let isSelected = engine.currentWallpaper?.id == item.id
                    Button(action: {
                        engine.setWallpaper(item)
                    }) {
                        HStack {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isSelected ? .accentColor : .secondary)
                                .font(.system(size: 12))
                            Text(item.title)
                                .font(.system(size: 12))
                            Spacer()
                        }
                        .padding(.vertical, 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Divider()
            
            // Navigation Actions
            VStack(spacing: 4) {
                Button(action: onOpenGallery) {
                    HStack {
                        Image(systemName: "photo.stack")
                        Text("Mở Wallpaper Studio...")
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
                
                Button(action: onOpenPreferences) {
                    HStack {
                        Image(systemName: "gearshape")
                        Text("Cài đặt...")
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
                
                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")
                            .foregroundColor(.red)
                        Text("Thoát Dynamic Wallpaper")
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .frame(width: 250)
    }
    
    private func selectNextWallpaper() {
        guard !library.wallpapers.isEmpty else { return }
        if let current = engine.currentWallpaper,
           let currentIndex = library.wallpapers.firstIndex(where: { $0.id == current.id }) {
            let nextIndex = (currentIndex + 1) % library.wallpapers.count
            engine.setWallpaper(library.wallpapers[nextIndex])
        } else if let first = library.wallpapers.first {
            engine.setWallpaper(first)
        }
    }
}
