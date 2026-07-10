import Foundation
import Observation

/// State machine for the parent-mode passcode gate.
///
/// First visit asks the parent to create a 4-digit passcode (entered twice);
/// later visits ask for it once. This is a child gate to keep editing tools
/// out of small hands, not a security feature.
@Observable
final class ParentGateViewModel {
    enum Stage {
        case createPasscode
        case confirmPasscode
        case enterPasscode
    }

    static let passcodeLength = 4

    private let settings: SettingsStore
    private var firstEntry = ""

    var stage: Stage
    var input = ""
    var errorMessage: String?
    private(set) var isUnlocked = false

    init(settings: SettingsStore) {
        self.settings = settings
        stage = settings.isParentPasscodeSet ? .enterPasscode : .createPasscode
    }

    var promptText: String {
        switch stage {
        case .createPasscode: "Choose a 4-digit parent passcode"
        case .confirmPasscode: "Enter the passcode again to confirm"
        case .enterPasscode: "Enter the parent passcode"
        }
    }

    func append(digit: Int) {
        guard input.count < Self.passcodeLength else { return }
        errorMessage = nil
        input.append(String(digit))
        if input.count == Self.passcodeLength {
            submit()
        }
    }

    func deleteLast() {
        guard !input.isEmpty else { return }
        input.removeLast()
    }

    private func submit() {
        switch stage {
        case .createPasscode:
            firstEntry = input
            input = ""
            stage = .confirmPasscode
        case .confirmPasscode:
            if input == firstEntry {
                settings.setParentPasscode(input)
                isUnlocked = true
            } else {
                errorMessage = "Passcodes didn't match. Try again."
                firstEntry = ""
                input = ""
                stage = .createPasscode
            }
        case .enterPasscode:
            if settings.validateParentPasscode(input) {
                isUnlocked = true
            } else {
                errorMessage = "Wrong passcode. Try again."
                input = ""
            }
        }
    }
}
