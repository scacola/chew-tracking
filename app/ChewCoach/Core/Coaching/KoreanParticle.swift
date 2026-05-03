import Foundation

/// 한국어 받침 자동 분기 헬퍼.
public enum KoreanParticle {
    public static func append(_ noun: String, _ withBatchim: String, _ withoutBatchim: String) -> String {
        guard let last = noun.last,
              let scalar = last.unicodeScalars.first?.value,
              scalar >= 0xAC00, scalar <= 0xD7A3 else {
            return noun + withoutBatchim
        }
        let hasBatchim = ((Int(scalar) - 0xAC00) % 28) != 0
        return noun + (hasBatchim ? withBatchim : withoutBatchim)
    }

    public static func eulReul(_ noun: String) -> String { append(noun, "을", "를") }
    public static func iGa(_ noun: String) -> String { append(noun, "이", "가") }
    public static func eunNeun(_ noun: String) -> String { append(noun, "은", "는") }
    public static func waGwa(_ noun: String) -> String { append(noun, "과", "와") }
}
