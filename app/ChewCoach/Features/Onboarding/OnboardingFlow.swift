import SwiftUI
import Observation

@MainActor
@Observable
final class OnboardingFlow {
    enum Step: Int, CaseIterable {
        case welcome = 0
        case persona
        case howItWorks
        case motionPermission
        case calibrationIntro

        var next: Step? { Step(rawValue: rawValue + 1) }
    }

    var step: Step = .welcome
    var selectedPersona: Persona?
    var didStartCalibration: Bool = false

    func goNext() {
        if let next = step.next {
            step = next
        }
    }

    func goBack() {
        if let prev = Step(rawValue: step.rawValue - 1) {
            step = prev
        }
    }
}
