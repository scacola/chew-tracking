import SwiftUI

enum AppMotion {
    static let defaultDuration: Double = 0.3
    static let longDuration: Double = 0.6
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)

    /// reduce-motion 환경에선 즉시 전환.
    static func adaptive(_ reduceMotion: Bool, default fallback: Animation = .easeInOut(duration: 0.3)) -> Animation {
        reduceMotion ? .linear(duration: 0) : fallback
    }
}

extension Int {
    /// "11분 32초" 형태.
    var formattedDurationKR: String {
        let minutes = self / 60
        let seconds = self % 60
        if minutes > 0 {
            return "\(minutes)분 \(seconds)초"
        } else {
            return "\(seconds)초"
        }
    }

    /// "11:32" 모노스페이스 타이머.
    var formattedTimerKR: String {
        let minutes = self / 60
        let seconds = self % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
