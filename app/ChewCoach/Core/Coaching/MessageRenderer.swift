import Foundation

public struct MessageRenderer: Sendable {
    public init() {}

    public func render(_ message: CoachingMessage, values: [String: any Sendable]) -> String? {
        var output = message.template
        for spec in message.variables {
            guard let value = values[spec.name] else { return nil }
            output = output.replacingOccurrences(of: "{{\(spec.name)}}",
                                                  with: format(value, kind: spec.kind))
        }
        return output
    }

    private func format(_ value: any Sendable, kind: VariableSpec.Kind) -> String {
        switch kind {
        case .int:
            if let int = value as? Int { return "\(int)" }
            if let double = value as? Double { return "\(Int(double.rounded()))" }
            return "0"
        case .double:
            if let double = value as? Double { return String(format: "%.1f", double) }
            if let int = value as? Int { return String(format: "%.1f", Double(int)) }
            return "0.0"
        case .string:
            return "\(value)"
        }
    }
}
