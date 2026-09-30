# Dynamic Wallpaper for macOS (Xcode Project)

Ứng dụng cài đặt hình nền động (Live / Dynamic Wallpaper) chuyên nghiệp dành cho macOS, được viết hoàn toàn bằng **Swift & SwiftUI** và thiết kế tối ưu cho **Xcode**.

---

## 🚀 Cách bắt đầu và chạy ứng dụng

### Cách 1: Mở trực tiếp bằng Xcode (Khuyên dùng)
1. Mở Terminal hoặc Finder, tìm đến thư mục:
   ```bash
   cd /Users/tranduchuy/.gemini/antigravity-ide/scratch/DynamicWallpaperMac
   ```
2. Mở file đồ án Xcode bằng lệnh:
   ```bash
   open DynamicWallpaper.xcodeproj
   ```
   *(hoặc nhấn đúp chuột vào file `DynamicWallpaper.xcodeproj` trong Finder)*
3. Trong giao diện Xcode:
   - Chọn mục tiêu chạy là **My Mac**.
   - Nhấn phím tắt **`Cmd + R`** (hoặc bấm nút **▶ Play** ở góc trên bên trái) để biên dịch và khởi chạy ứng dụng!

---

### Cách 2: Chạy trực tiếp ứng dụng đã được Build sẵn
Ứng dụng đã được biên dịch sẵn thành file `.app` độc lập. Bạn chỉ cần gõ lệnh sau để mở ngay:
```bash
open /Users/tranduchuy/.gemini/antigravity-ide/scratch/DynamicWallpaperMac/build/DynamicWallpaper.app
```

---

### Cách 3: Chạy nhanh qua Swift Package Manager
```bash
cd /Users/tranduchuy/.gemini/antigravity-ide/scratch/DynamicWallpaperMac
swift run
```

---

## 🌟 Các tính năng nổi bật đã được lập trình sẵn

1. **Hiển thị hình nền mượt mà dưới Desktop Icons**:
   - Cửa sổ hình nền nằm ở tầng `desktopIconWindow - 1`, giúp bạn thoải mái click, kéo thả file và biểu tượng ngoài màn hình Desktop mà không bị che khuất.
2. **Bộ lặp video AVPlayerLooper phần cứng**:
   - Sử dụng `AVQueuePlayer` và `AVPlayerLooper` của Apple, looping vô tận không giật khựng và không chớp nháy đen.
3. **Thư viện mẫu tích hợp (Built-in Presets)**:
   - Tự động tạo 3 hình nền video mẫu 60fps tuyệt đẹp khi mở app lần đầu:
     - *Aurora Borealis* (Cực quang huyền ảo)
     - *Cyber Sunset Grid* (Lưới Neon Synthwave cổ điển)
     - *Liquid Cosmic Gradient* (Dòng chảy vũ trụ êm dịu)
4. **Nhập video tuỳ chọn**:
   - Kéo thả (Drag & Drop) hoặc bấm "Add Wallpaper" để chọn video `.mp4`, `.mov`, `.m4v` từ máy. Tự sinh ảnh thumbnail sắc nét.
5. **Tiện ích Menu Bar**:
   - Biểu tượng tinh tế trên thanh Menu Bar cho phép Play/Pause, Mute/Unmute, đổi hình nền nhanh và mở Settings.
6. **Tối ưu Pin & Tiết kiệm năng lượng**:
   - Tuỳ chọn tự động dừng video khi rút sạc (dùng pin) hoặc khi mở ứng dụng toàn màn hình (Fullscreen Spaces).
7. **Hỗ trợ Đa màn hình (Multi-Display)**:
   - Giao diện trực quan chọn hình nền riêng cho từng màn hình ngoài hoặc đồng bộ tất cả màn hình.
