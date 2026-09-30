import AppKit
import Combine

public class ScreenObserver {
    public static let shared = ScreenObserver()
    
    public var onScreensChanged: (([NSScreen]) -> Void)?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.onScreensChanged?(NSScreen.screens)
            }
            .store(in: &cancellables)
    }
}
