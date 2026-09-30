import AppKit
import AVFoundation

public class VideoPlayerController {
    public let playerLayer: AVPlayerLayer
    private var queuePlayer: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var currentURL: URL?
    private var endObserver: NSObjectProtocol?
    
    public private(set) var isPlaying: Bool = false
    public var currentVolume: Float = 0.0 {
        didSet {
            queuePlayer?.volume = isMuted ? 0.0 : currentVolume
        }
    }
    public var isMuted: Bool = true {
        didSet {
            queuePlayer?.isMuted = isMuted
            queuePlayer?.volume = isMuted ? 0.0 : currentVolume
        }
    }
    public var playbackRate: Float = 1.0 {
        didSet {
            if isPlaying {
                queuePlayer?.rate = playbackRate
            }
        }
    }
    
    public init() {
        self.playerLayer = AVPlayerLayer()
        self.playerLayer.videoGravity = .resizeAspectFill
        self.playerLayer.backgroundColor = NSColor.black.cgColor
    }
    
    public func loadVideo(url: URL, autoPlay: Bool = true) {
        stop()
        self.currentURL = url
        
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        let player = AVQueuePlayer(playerItem: playerItem)
        player.actionAtItemEnd = .none
        player.isMuted = isMuted
        player.volume = isMuted ? 0.0 : currentVolume
        
        // Try AVPlayerLooper for zero-gap looping
        self.playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        self.queuePlayer = player
        self.playerLayer.player = player
        
        // Failsafe loop notification: if AVPlayerLooper fails on certain codecs, this restarts it immediately
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
        
        if autoPlay {
            play()
        }
    }
    
    public func play() {
        guard let player = queuePlayer else { return }
        player.play()
        player.rate = playbackRate
        isPlaying = true
    }
    
    public func pause() {
        guard let player = queuePlayer else { return }
        player.pause()
        isPlaying = false
    }
    
    public func stop() {
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
        queuePlayer?.pause()
        queuePlayer?.removeAllItems()
        playerLooper?.disableLooping()
        playerLooper = nil
        queuePlayer = nil
        playerLayer.player = nil
        isPlaying = false
    }
    
    public func setGravity(_ gravityString: String) {
        switch gravityString {
        case "resizeAspect":
            playerLayer.videoGravity = .resizeAspect
        case "resize":
            playerLayer.videoGravity = .resize
        default:
            playerLayer.videoGravity = .resizeAspectFill
        }
    }
    
    deinit {
        stop()
    }
}
