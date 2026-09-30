import SwiftUI
import AppKit

public struct PreferencesView: View {
    @ObservedObject var settings = AppSettings.shared
    
    public init() {}
    
    public var body: some View {
        Form {
            Section(header: Text("Phát lại & Âm thanh").font(.headline)) {
                // Mute
                Toggle("Tắt âm thanh (Khuyên dùng cho hình nền)", isOn: $settings.isMuted)
                
                // Volume Slider
                if !settings.isMuted {
                    HStack {
                        Image(systemName: "speaker.wave.1")
                        Slider(value: $settings.volume, in: 0.0...1.0)
                        Image(systemName: "speaker.wave.3")
                        Text("\(Int(settings.volume * 100))%")
                            .frame(width: 40, alignment: .trailing)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
                
                // Playback speed
                Picker("Tốc độ phát", selection: $settings.playbackRate) {
                    Text("0.5x (Chậm)").tag(Float(0.5))
                    Text("0.75x").tag(Float(0.75))
                    Text("1.0x (Bình thường)").tag(Float(1.0))
                    Text("1.25x").tag(Float(1.25))
                    Text("1.5x (Nhanh)").tag(Float(1.5))
                }
                
                // Scaling mode
                Picker("Chế độ co giãn", selection: $settings.videoGravity) {
                    Text("Lấp đầy (Lấp đầy màn hình, cắt phần thừa)").tag("resizeAspectFill")
                    Text("Vừa vặn (Giữ nguyên toàn bộ video)").tag("resizeAspect")
                    Text("Kéo giãn để lấp đầy").tag("resize")
                }
            }
            .padding(.vertical, 4)
            
            Divider()
            
            Section(header: Text("Hiệu suất & Pin").font(.headline)) {
                Toggle("Tạm dừng phát khi sử dụng pin", isOn: $settings.pauseOnBattery)
                Text("Kéo dài tuổi thọ pin MacBook khi không cắm sạc.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("Tạm dừng phát khi có ứng dụng toàn màn hình", isOn: $settings.pauseOnFullscreen)
                Text("Tiết kiệm tài nguyên CPU và GPU khi bạn đang làm việc trong cửa sổ toàn màn hình hoặc chơi game.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            
            Divider()
            
            Section(header: Text("Tích hợp hệ thống").font(.headline)) {
                Toggle("Khởi động cùng hệ thống", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { newValue in
                        settings.launchAtLogin = newValue
                        LaunchAtLoginHelper.isEnabled = newValue
                    }
                ))
                
                Toggle("Hiển thị biểu tượng ứng dụng trên Dock", isOn: Binding(
                    get: { settings.showInDock },
                    set: { newValue in
                        settings.showInDock = newValue
                        updateDockVisibility(show: newValue)
                    }
                ))
                Text("Nếu tắt, Dynamic Wallpaper sẽ chỉ chạy từ thanh Menu Bar ở đầu màn hình.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .padding(24)
        .frame(maxWidth: 550)
    }
    
    private func updateDockVisibility(show: Bool) {
        if show {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
