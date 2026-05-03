import XCTest
@testable import ChewCoach

final class MessageLibraryTests: XCTestCase {

    // 라이브러리 카피 lint — 의료 약속·영어 placeholder·실패 톤 차단
    private static let forbiddenSubstrings: [String] = [
        "치료", "회복 보장", "완치", "100%", "정확하게 측정",
        "체중 ", "다이어트 보장", "왜 또", "안 좋아요", "실패",
        " track", "data ", "stats", "monitor ", "score",
        "환자", "회원님"
    ]

    func test_libraryHas32Messages() {
        XCTAssertEqual(MessageLibrary.library.count, 32,
                       "MessageLibrary는 정확히 32개 메시지를 가져야 함")
    }

    func test_categoryDistribution() {
        let counts = Dictionary(grouping: MessageLibrary.library, by: \.category).mapValues(\.count)
        XCTAssertEqual(counts[.encouragement], 10, "encouragement = 10")
        XCTAssertEqual(counts[.insight], 10, "insight = 10")
        XCTAssertEqual(counts[.awareness], 5, "awareness = 5")
        XCTAssertEqual(counts[.celebration], 5, "celebration = 5")
        XCTAssertEqual(counts[.weekly], 2, "weekly = 2")
    }

    func test_allMessages_haveNoForbiddenExpressions() {
        for msg in MessageLibrary.library {
            for forbidden in Self.forbiddenSubstrings {
                XCTAssertFalse(
                    msg.template.contains(forbidden),
                    "[\(msg.id)] 금지어 '\(forbidden)' 포함: \(msg.template)"
                )
            }
        }
    }

    func test_allMessages_useHaeyoForm() {
        // 모든 메시지에 해요체("요." / "요!" / "요?") 표현이 *최소 1회* 포함되어야 함.
        // 문장 끝 분기 일부는 시적 단편 ("한 손은 천천히.") 허용 — 최종 문장 강제는 X.
        // 영어 placeholder·반말·체언 종결 0건 가드.
        for msg in MessageLibrary.library {
            let template = msg.template
            let containsHaeyo = template.contains("요.") || template.contains("요!") || template.contains("요?")
            XCTAssertTrue(containsHaeyo,
                          "[\(msg.id)] 해요체 표현 미포함: '\(template)'")
        }
    }

    func test_messageRenderer_substitutesAllVariables() {
        let renderer = MessageRenderer()
        let msg = MessageLibrary.library.first { $0.id == "enc_slowed_down_d2d" }!
        let rendered = renderer.render(msg, values: ["deltaSec": 60])
        XCTAssertEqual(rendered, "어제보다 60초 차분해졌어요. 잘하고 계세요.")
    }

    func test_messageRenderer_returnsNilWhenVariableMissing() {
        let renderer = MessageRenderer()
        let msg = MessageLibrary.library.first { $0.id == "enc_slowed_down_d2d" }!
        let rendered = renderer.render(msg, values: [:])
        XCTAssertNil(rendered, "변수 누락 시 nil 반환")
    }

    func test_koreanParticle_eulReul_handlesBatchim() {
        XCTAssertEqual(KoreanParticle.eulReul("물"), "물을")  // 받침 있음
        XCTAssertEqual(KoreanParticle.eulReul("나"), "나를")  // 받침 없음
    }

    func test_koreanParticle_iGa_handlesBatchim() {
        XCTAssertEqual(KoreanParticle.iGa("선생님"), "선생님이")
        XCTAssertEqual(KoreanParticle.iGa("학교"), "학교가")
    }
}
