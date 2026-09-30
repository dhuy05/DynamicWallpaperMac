import SwiftUI
import AppKit

public struct WallpaperCardView: View {
    public let item: WallpaperItem
    public let isSelected: Bool
    public let onSelect: () -> Void
    public let onDelete: (() -> Void)?
    
    @State private var isHovered: Bool = false
    @State private var thumbnailImage: NSImage? = nil
    
    public init(
        item: WallpaperItem,
        isSelected: Bool,
        onSelect: @escaping () -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.item = item
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onDelete = onDelete
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Thumbnail container
            ZStack(alignment: .topTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.4))
                    
                    if let image = thumbnailImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 140)
                            .clipped()
                            .cornerRadius(12)
                    } else {
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Đang tải...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 140)
                    }
                    
                    // Hover play preview indicator
                    if isHovered {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: isSelected ? "checkmark" : "play.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .offset(x: isSelected ? 0 : 2)
                            )
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 140)
                
                // Active Badge or Delete button
                HStack(spacing: 6) {
                    if isSelected {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 7, height: 7)
                            Text("ĐANG CHẠY")
                                .font(.system(size: 9, weight: .black))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(6)
                        .foregroundColor(.white)
                    }
                    
                    if !item.isBuiltIn, let onDelete = onDelete, isHovered {
                        Button(action: onDelete) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.red.opacity(0.8))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .transition(.scale)
                    }
                }
                .padding(8)
            }
            
            // Metadata
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(item.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    Spacer()
                    if item.isBuiltIn {
                        Text("CÓ SẴN")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
                
                HStack {
                    Text(item.resolutionText)
                    Text("•")
                    Text(item.formattedDuration)
                }
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.white.opacity(isHovered ? 0.08 : 0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.accentColor : Color.white.opacity(isHovered ? 0.2 : 0.08), lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: isSelected ? Color.accentColor.opacity(0.25) : Color.black.opacity(0.2), radius: isHovered ? 8 : 4, y: 3)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .task {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        if let thumbURL = item.thumbnailURL, let img = NSImage(contentsOf: thumbURL) {
            self.thumbnailImage = img
        } else {
            Task {
                if let generated = await ThumbnailGenerator.shared.generateThumbnail(for: item.fileURL, at: 0.5) {
                    await MainActor.run {
                        self.thumbnailImage = generated
                    }
                }
            }
        }
    }
}
