import AppKit
import AVFoundation

public class DesktopWindow: NSWindow {
    public let targetScreen: NSScreen
    public private(set) var playerController: VideoPlayerController?
    
    public init(screen: NSScreen) {
        self.targetScreen = screen
        
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        setupDesktopAttributes()
    }
    
    private func setupDesktopAttributes() {
        // Place behind desktop icons (Finder icons and desktop items)
        let desktopLevel = Int(CGWindowLevelForKey(.desktopIconWindow)) - 1
        self.level = NSWindow.Level(desktopLevel)
        
        // Show on all spaces/desktops, stay stationary, don't cycle with Cmd+Tab
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        self.canHide = false
        self.hasShadow = false
        self.isOpaque = true
        self.backgroundColor = .black
        
        // Transparent to mouse clicks so users can click desktop files and drag selections
        self.ignoresMouseEvents = true
        
        let containerView = NSView(frame: NSRect(origin: .zero, size: targetScreen.frame.size))
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.black.cgColor
        self.contentView = containerView
        
        self.orderFrontRegardless()
    }
    
    public func attachPlayerController(_ controller: VideoPlayerController) {
        self.playerController = controller
        
        guard let contentView = self.contentView, let layer = contentView.layer else { return }
        
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let playerLayer = controller.playerLayer
        playerLayer.frame = contentView.bounds
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layer.addSublayer(playerLayer)
        
        self.orderFrontRegardless()
    }
    
    public func updateFrame() {
        self.setFrame(targetScreen.frame, display: true)
        if let contentView = self.contentView {
            contentView.frame = NSRect(origin: .zero, size: targetScreen.frame.size)
            playerController?.playerLayer.frame = contentView.bounds
        }
        self.orderFrontRegardless()
    }
    
    deinit {
        playerController?.stop()
    }
}
