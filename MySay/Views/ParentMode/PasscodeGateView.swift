import SwiftUI

/// Passcode entry sheet guarding Parent Mode. Creates the passcode on
/// first use, verifies it afterwards.
struct PasscodeGateView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.dismiss) private var dismiss

    let onUnlock: () -> Void

    @State private var viewModel: ParentGateViewModel?
    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize = 52

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                if let viewModel {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: symbolSize))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)

                    Text(viewModel.promptText)
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)

                    dots(for: viewModel)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.body)
                            .foregroundStyle(.red)
                    }

                    keypad(for: viewModel)
                }
            }
            .padding(32)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Parent Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = ParentGateViewModel(settings: settings)
                }
            }
            .onChange(of: viewModel?.isUnlocked ?? false) { _, unlocked in
                if unlocked { onUnlock() }
            }
        }
    }

    private func dots(for viewModel: ParentGateViewModel) -> some View {
        HStack(spacing: 18) {
            ForEach(0..<ParentGateViewModel.passcodeLength, id: \.self) { index in
                Circle()
                    .fill(index < viewModel.input.count ? Color.accentColor : Color(.systemGray4))
                    .frame(width: 18, height: 18)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(viewModel.input.count) of \(ParentGateViewModel.passcodeLength) digits entered")
    }

    private func keypad(for viewModel: ParentGateViewModel) -> some View {
        VStack(spacing: 14) {
            ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                HStack(spacing: 14) {
                    ForEach(row, id: \.self) { digit in
                        keypadButton(digit, viewModel: viewModel)
                    }
                }
            }
            HStack(spacing: 14) {
                Color.clear.frame(width: 84, height: 84)
                keypadButton(0, viewModel: viewModel)
                Button {
                    viewModel.deleteLast()
                } label: {
                    Image(systemName: "delete.left")
                        .font(.title)
                        .frame(width: 84, height: 84)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Delete last digit")
            }
        }
    }

    private func keypadButton(_ digit: Int, viewModel: ParentGateViewModel) -> some View {
        Button {
            viewModel.append(digit: digit)
        } label: {
            Text("\(digit)")
                .font(.title.weight(.medium))
                .frame(width: 84, height: 84)
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
        .accessibilityLabel("Digit \(digit)")
    }
}
