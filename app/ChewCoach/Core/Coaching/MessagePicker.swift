import Foundation

public struct MessagePicker: Sendable {
    let evaluator: TriggerEvaluator

    public init(evaluator: TriggerEvaluator = .init()) {
        self.evaluator = evaluator
    }

    public func pick(category: CoachingMessage.Category, context: CoachingContext) -> CoachingMessage? {
        MessageLibrary.library
            .filter { $0.category == category }
            .first { evaluator.evaluate($0.trigger, context: context) }
    }

    public func pickAny(context: CoachingContext) -> CoachingMessage? {
        for category in CoachingMessage.Category.allCases {
            if let msg = pick(category: category, context: context) {
                return msg
            }
        }
        return nil
    }
}
