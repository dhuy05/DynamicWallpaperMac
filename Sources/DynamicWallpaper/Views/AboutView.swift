import SwiftUI

public struct AboutView: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // App Icon
            if let icon = NSImage(named: "AppIcon") {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 128, height: 128)
                    .cornerRadius(28)
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            
            VStack(spacing: 8) {
                Text("Dynamic Wallpaper Studio")
                    .font(.system(size: 28, weight: .bold))
                
                Text("Phiên bản 1.0")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                Text("Ứng dụng hình nền động tối ưu, mượt mà và tiết kiệm pin dành riêng cho macOS. Mang đến không gian làm việc sống động và đầy cảm hứng.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: 400)
                
                Link(destination: URL(string: "https://dhuy05.github.io/DynamicWallpaperMac/")!) {
                    HStack {
                        Image(systemName: "globe")
                        Text("Trang chủ ứng dụng")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.top, 10)
            
            Spacer()
            
            // Signature
            VStack(spacing: 4) {
                Text("Crafted by Dhuy")
                    .font(.custom("SignPainter", size: 36))
                    .foregroundColor(Color(red: 1.0, green: 0.1, blue: 0.8)) // Neon Pink
                    .shadow(color: Color(red: 1.0, green: 0.1, blue: 0.8).opacity(0.8), radius: 4, x: 0, y: 0)
                
                Text("© 2026 Trần Đức Huy. All rights reserved.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
