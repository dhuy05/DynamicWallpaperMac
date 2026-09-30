import SwiftUI
import AppKit

public struct DisplayManagerView: View {
    @ObservedObject var engine = WallpaperEngine.shared
    @ObservedObject var library = WallpaperLibraryStore.shared
    @ObservedObject var settings = AppSettings.shared
    
    @State private var screens: [NSScreen] = NSScreen.screens
    @State private var selectedScreenId: String = ""
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Cấu hình đa màn hình")
                .font(.title2.bold())
            
            Text("Gán hình nền riêng biệt cho từng màn hình hoặc áp dụng một hình nền cho tất cả màn hình.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Screen Layout Preview
            HStack(spacing: 20) {
                ForEach(Array(screens.enumerated()), id: \.offset) { index, screen in
                    let screenId = engine.screenIdentifier(for: screen)
                    let isCurrentSelected = selectedScreenId == screenId || (selectedScreenId.isEmpty && index == 0)
                    let assignedWallpaper = getWallpaper(for: screenId)
                    
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isCurrentSelected ? Color.accentColor.opacity(0.15) : Color.black.opacity(0.3))
                                .frame(width: 180, height: 110)
                            
                            VStack(spacing: 6) {
                                Image(systemName: "display")
                                    .font(.system(size: 28))
                                    .foregroundColor(isCurrentSelected ? .accentColor : .secondary)
                                
                                Text("Màn hình \(index + 1)")
                                    .font(.system(size: 12, weight: .bold))
                                
                                Text("\(Int(screen.frame.width)) × \(Int(screen.frame.height))")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            
                            if let wp = assignedWallpaper {
                                VStack {
                                    Spacer()
                                    Text(wp.title)
                                        .font(.system(size: 9, weight: .semibold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(4)
                                        .padding(.bottom, 6)
                                }
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isCurrentSelected ? Color.accentColor : Color.white.opacity(0.1), lineWidth: 2)
                        )
                        .onTapGesture {
                            selectedScreenId = screenId
                        }
                        
                        Text(index == 0 ? "Màn hình chính" : "Màn hình phụ")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 10)
            
            Divider()
            
            // Choose wallpaper for selected screen
            VStack(alignment: .leading, spacing: 12) {
                Text("Chọn hình nền cho \(currentScreenName):")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(library.wallpapers) { item in
                            let isTarget = getWallpaper(for: currentActiveScreenId)?.id == item.id
                            
                            Button(action: {
                                engine.setWallpaper(item, forScreen: currentActiveScreenId)
                            }) {
                                VStack(spacing: 6) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.black.opacity(0.3))
                                            .frame(width: 120, height: 75)
                                        
                                        if let thumb = item.thumbnailURL, let img = NSImage(contentsOf: thumb) {
                                            Image(nsImage: img)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 120, height: 75)
                                                .clipped()
                                                .cornerRadius(8)
                                        }
                                        
                                        if isTarget {
                                            Circle()
                                                .fill(Color.green)
                                                .frame(width: 20, height: 20)
                                                .overlay(Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white))
                                        }
                                    }
                                    
                                    Text(item.title)
                                        .font(.system(size: 10, weight: .medium))
                                        .lineLimit(1)
                                        .frame(width: 120)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Spacer()
            
            // Apply to all button
            HStack {
                Spacer()
                Button("Áp dụng cho tất cả màn hình") {
                    if let current = engine.currentWallpaper {
                        engine.setWallpaper(current)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .onAppear {
            screens = NSScreen.screens
            if let first = screens.first {
                selectedScreenId = engine.screenIdentifier(for: first)
            }
        }
    }
    
    private var currentActiveScreenId: String {
        if !selectedScreenId.isEmpty { return selectedScreenId }
        if let first = screens.first { return engine.screenIdentifier(for: first) }
        return ""
    }
    
    private var currentScreenName: String {
        for (i, screen) in screens.enumerated() {
            if engine.screenIdentifier(for: screen) == currentActiveScreenId {
                return "Màn hình \(i + 1)"
            }
        }
        return "Màn hình đã chọn"
    }
    
    private func getWallpaper(for screenId: String) -> WallpaperItem? {
        if let idString = settings.screenWallpaperMap[screenId],
           let uuid = UUID(uuidString: idString) {
            return library.wallpapers.first(where: { $0.id == uuid })
        }
        return engine.currentWallpaper
    }
}
