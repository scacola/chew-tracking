import SwiftUI

extension Font {
    static let displayLarge = Font.largeTitle.weight(.bold)
    static let title1S = Font.title.weight(.semibold)
    static let title2S = Font.title2.weight(.semibold)
    static let title3R = Font.title3
    static let headlineS = Font.headline
    static let bodyR = Font.body
    static let calloutR = Font.callout
    static let caption1R = Font.caption
    static let caption2R = Font.caption2
    /// 타이머 표시용 — Dynamic Type 반영. relativeTo: .largeTitle로 지정해
    /// 사용자가 텍스트 크기를 키우면 함께 커짐 (XL/AX1~AX5 모두 적용).
    static let timerDisplay = Font.system(size: 56, weight: .semibold, design: .monospaced)
        .leading(.tight)
    /// 타이머 표시용 (Dynamic Type 적응형). View에서 `.font(.system(.largeTitle, design: .monospaced).weight(.semibold))` 대체로도 사용 가능.
    static let timerDisplayDynamic = Font.system(.largeTitle, design: .monospaced).weight(.semibold)
}
