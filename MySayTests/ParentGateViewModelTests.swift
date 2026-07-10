import Testing
@testable import MySay

@MainActor
@Suite("Parent gate")
struct ParentGateViewModelTests {
    @Test("First use walks through create and confirm")
    func createFlow() {
        let settings = SettingsStore(defaults: TestSupport.makeDefaults())
        let gate = ParentGateViewModel(settings: settings)
        #expect(gate.stage == .createPasscode)

        for digit in [1, 2, 3, 4] { gate.append(digit: digit) }
        #expect(gate.stage == .confirmPasscode)
        #expect(!gate.isUnlocked)

        for digit in [1, 2, 3, 4] { gate.append(digit: digit) }
        #expect(gate.isUnlocked)
        #expect(settings.isParentPasscodeSet)
        #expect(settings.validateParentPasscode("1234"))
    }

    @Test("Mismatched confirmation restarts creation")
    func mismatchedConfirmation() {
        let settings = SettingsStore(defaults: TestSupport.makeDefaults())
        let gate = ParentGateViewModel(settings: settings)

        for digit in [1, 2, 3, 4] { gate.append(digit: digit) }
        for digit in [9, 9, 9, 9] { gate.append(digit: digit) }

        #expect(!gate.isUnlocked)
        #expect(gate.stage == .createPasscode)
        #expect(gate.errorMessage != nil)
        #expect(!settings.isParentPasscodeSet)
    }

    @Test("Existing passcode unlocks only on the right code")
    func enterFlow() {
        let settings = SettingsStore(defaults: TestSupport.makeDefaults())
        settings.setParentPasscode("2580")

        let gate = ParentGateViewModel(settings: settings)
        #expect(gate.stage == .enterPasscode)

        for digit in [1, 1, 1, 1] { gate.append(digit: digit) }
        #expect(!gate.isUnlocked)
        #expect(gate.errorMessage != nil)
        #expect(gate.input.isEmpty)

        for digit in [2, 5, 8, 0] { gate.append(digit: digit) }
        #expect(gate.isUnlocked)
    }

    @Test("Delete removes the last digit")
    func deleteDigit() {
        let settings = SettingsStore(defaults: TestSupport.makeDefaults())
        let gate = ParentGateViewModel(settings: settings)
        gate.append(digit: 1)
        gate.append(digit: 2)
        gate.deleteLast()
        #expect(gate.input == "1")
    }
}
