import Foundation
import Observation
#if canImport(AVFoundation)
import AVFoundation
#endif

@MainActor
@Observable
final class AudioSessionMonitor {
    var isVideoPlaying: Bool = false
    private var timer: Timer?

    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            #if canImport(AVFoundation)
            let playing = AVAudioSession.sharedInstance().isOtherAudioPlaying
            Task { @MainActor in
                self?.isVideoPlaying = playing
            }
            #endif
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
