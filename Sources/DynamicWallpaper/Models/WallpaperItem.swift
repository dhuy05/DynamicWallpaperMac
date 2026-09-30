import Foundation
import CoreGraphics

public struct WallpaperItem: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var title: String
    public var fileURL: URL
    public var thumbnailURL: URL?
    public var duration: TimeInterval
    public var width: Int
    public var height: Int
    public var isBuiltIn: Bool
    public var dateAdded: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        fileURL: URL,
        thumbnailURL: URL? = nil,
        duration: TimeInterval = 0,
        width: Int = 1920,
        height: Int = 1080,
        isBuiltIn: Bool = false,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.fileURL = fileURL
        self.thumbnailURL = thumbnailURL
        self.duration = duration
        self.width = width
        self.height = height
        self.isBuiltIn = isBuiltIn
        self.dateAdded = dateAdded
    }
    
    public var resolutionText: String {
        if width > 0 && height > 0 {
            if width >= 3840 {
                return "4K UHD (\(width)×\(height))"
            } else if width >= 2560 {
                return "2K QHD (\(width)×\(height))"
            } else {
                return "Full HD (\(width)×\(height))"
            }
        }
        return "Video Loop"
    }
    
    public var formattedDuration: String {
        let seconds = Int(duration)
        let m = seconds / 60
        let s = seconds % 60
        if m > 0 {
            return String(format: "%d:%02d", m, s)
        } else {
            return "\(s)s loop"
        }
    }
}
