import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct MainWindowView: View {
    @ObservedObject var library = WallpaperLibraryStore.shared
    @ObservedObject var engine = WallpaperEngine.shared
    @ObservedObject var settings = AppSettings.shared
    
    @State private var selectedTab: SidebarTab = .gallery
    @State private var isTargetedForDrop: Bool = false
    @State private var isImporting: Bool = false
    @State private var importErrorMessage: String? = nil
    
    enum SidebarTab: String, CaseIterable, Identifiable {
        case gallery = "Thư viện"
        case displays = "Màn hình"
        case preferences = "Cài đặt"
        
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .gallery: return "photo.on.rectangle.angled"
            case .displays: return "display.2"
            case .preferences: return "gearshape"
            }
        }
    }
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SidebarTab.allCases, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(tab.rawValue, systemImage: tab.icon)
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 180, idealWidth: 200)
            .navigationSplitViewColumnWidth(min: 170, ideal: 200, max: 240)
            
            // Sidebar Bottom: Current Live Info
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                HStack {
                    Circle()
                        .fill(engine.isEnginePlaying ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(engine.isEnginePlaying ? "Đang chạy" : "Đã tạm dừng")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                }
                Text("\(NSScreen.screens.count) màn hình hoạt động")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer().frame(height: 16)
                
                // Signature
                Text("Crafted by Dhuy")
                    .font(.custom("SignPainter", size: 24))
                    .foregroundColor(.accentColor)
                    .opacity(0.8)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 8)
            }
            .padding(12)
            
        } detail: {
            ZStack {
                switch selectedTab {
                case .gallery:
                    galleryContent
                case .displays:
                    DisplayManagerView()
                case .preferences:
                    PreferencesView()
                }
                
                // Drop Overlay
                if isTargetedForDrop {
                    ZStack {
                        Color.accentColor.opacity(0.15)
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [8]))
                            .padding(20)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.accentColor)
                            Text("Thả tệp video vào đây để thêm")
                                .font(.title2.bold())
                                .foregroundColor(.accentColor)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .navigationTitle(selectedTab.rawValue)
            .toolbar {
                if selectedTab == .gallery {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: openFilePicker) {
                            Label("Thêm video", systemImage: "plus.rectangle.on.folder.fill")
                        }
                        .help("Thêm tệp video (.mp4, .mov, .m4v)")
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 550)
        .onDrop(of: [UTType.movie.identifier, UTType.mpeg4Movie.identifier, UTType.quickTimeMovie.identifier, UTType.fileURL.identifier], isTargeted: $isTargetedForDrop) { providers in
            handleDrop(providers: providers)
        }
    }
    
    // Gallery View with Grid
    private var galleryContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Banner / Import Drop Target
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dynamic Wallpaper Studio")
                                .font(.title.bold())
                            Text("Chọn một hình nền động bên dưới hoặc thêm video độ phân giải cao của riêng bạn.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: openFilePicker) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                Text("Thêm hình nền")
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    if library.isLoading {
                        HStack {
                            Spacer()
                            ProgressView("Đang chuẩn bị hình nền...")
                                .padding(40)
                            Spacer()
                        }
                    } else {
                        // Wallpaper Grid
                        LazyVGrid(
                            columns: [
                                GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 18)
                            ],
                            spacing: 18
                        ) {
                            ForEach(library.wallpapers) { item in
                                let isSelected = engine.currentWallpaper?.id == item.id
                                
                                WallpaperCardView(
                                    item: item,
                                    isSelected: isSelected,
                                    onSelect: {
                                        engine.setWallpaper(item)
                                    },
                                    onDelete: item.isBuiltIn ? nil : {
                                        library.removeWallpaper(item)
                                    }
                                )
                            }
                        }
                        .padding(24)
                    }
                }
            }
            
            // Bottom Controls Bar
            bottomControlBar
        }
    }
    
    private var bottomControlBar: some View {
        HStack(spacing: 16) {
            if let current = engine.currentWallpaper {
                HStack(spacing: 10) {
                    if let thumb = current.thumbnailURL, let img = NSImage(contentsOf: thumb) {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 28)
                            .cornerRadius(4)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(current.title)
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                        Text(current.resolutionText)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Play/Pause button
            Button(action: {
                engine.togglePlayback()
            }) {
                Image(systemName: engine.isEnginePlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.bordered)
            
            // Audio Mute toggle
            Button(action: {
                settings.isMuted.toggle()
            }) {
                Image(systemName: settings.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 14))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.bordered)
            
            // Volume Slider
            if !settings.isMuted {
                HStack(spacing: 6) {
                    Slider(value: $settings.volume, in: 0.0...1.0)
                        .frame(width: 80)
                }
            }
            
            Divider()
                .frame(height: 20)
            
            // Done / Hide to Menu Bar button
            Button(action: {
                AppDelegate.shared.closeMainWindow()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "menubar.arrow.up.rectangle")
                    Text("Xong & Ẩn khỏi Dock")
                }
                .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .help("Đóng cửa sổ cài đặt và ẩn ứng dụng khỏi thanh Dock (chỉ chạy trên thanh Menu Bar)")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
    
    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.movie, UTType.mpeg4Movie, UTType.quickTimeMovie]
        panel.message = "Chọn video để làm hình nền động"
        panel.prompt = "Thêm hình nền"
        
        if panel.runModal() == .OK, let url = panel.url {
            Task {
                if let newItem = await library.importVideo(from: url) {
                    engine.setWallpaper(newItem)
                }
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            if let data = item as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                Task {
                    if let newItem = await library.importVideo(from: url) {
                        await MainActor.run {
                            engine.setWallpaper(newItem)
                        }
                    }
                }
            } else if let url = item as? URL {
                Task {
                    if let newItem = await library.importVideo(from: url) {
                        await MainActor.run {
                            engine.setWallpaper(newItem)
                        }
                    }
                }
            }
        }
        return true
    }
}
