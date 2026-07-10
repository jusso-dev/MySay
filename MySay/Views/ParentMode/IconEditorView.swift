import PhotosUI
import SwiftData
import SwiftUI

/// Create or edit an icon: name, spoken phrase, category, colour, and
/// artwork (SF Symbol, photo library, or camera — e.g. a photo of the
/// child's actual cup).
struct IconEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \IconCategory.sortOrder) private var categories: [IconCategory]

    @Environment(SpeechService.self) private var speech
    @Environment(SettingsStore.self) private var settings

    @State private var viewModel: IconEditorViewModel
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var recordingService = AudioRecordingService()
    @State private var micPermissionDenied = false

    private let isEditing: Bool

    init(icon: IconItem?, defaultCategoryID: UUID? = nil) {
        _viewModel = State(initialValue: IconEditorViewModel(
            icon: icon,
            defaultCategoryID: defaultCategoryID
        ))
        isEditing = icon != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Word") {
                    TextField("Name (shown on the tile)", text: $viewModel.title)
                    TextField(
                        "Spoken phrase (optional, defaults to the name)",
                        text: $viewModel.phraseText
                    )
                }

                Section("Category") {
                    Picker("Category", selection: $viewModel.selectedCategoryID) {
                        Text("Choose…").tag(UUID?.none)
                        ForEach(categories) { category in
                            Text(category.name).tag(UUID?.some(category.id))
                        }
                    }
                }

                Section("Picture") {
                    HStack(spacing: 20) {
                        IconImageView(
                            imageName: viewModel.symbolName,
                            customImageData: viewModel.customImageData,
                            accent: viewModel.tileColor.accent
                        )
                        .frame(width: 88, height: 88)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(viewModel.tileColor.fill)
                        )
                        .accessibilityLabel("Current picture preview")

                        VStack(alignment: .leading, spacing: 12) {
                            PhotosPicker(selection: $photoItem, matching: .images) {
                                Label("Choose Photo", systemImage: "photo.on.rectangle")
                            }
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                Button {
                                    showCamera = true
                                } label: {
                                    Label("Take Photo", systemImage: "camera")
                                }
                            }
                            if viewModel.customImageData != nil {
                                Button(role: .destructive) {
                                    viewModel.clearPhoto()
                                } label: {
                                    Label("Remove Photo", systemImage: "trash")
                                }
                            }
                        }
                    }

                    if viewModel.customImageData == nil {
                        TextField("Symbol name (SF Symbol)", text: $viewModel.symbolName)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }

                Section {
                    if viewModel.recordedAudioData != nil {
                        Button {
                            speech.playRecording(
                                viewModel.recordedAudioData ?? Data(),
                                fallbackText: viewModel.effectivePhrase,
                                settings: settings
                            )
                        } label: {
                            Label("Play Recording", systemImage: "play.circle.fill")
                        }
                        Button(role: .destructive) {
                            viewModel.recordedAudioData = nil
                        } label: {
                            Label("Remove Recording", systemImage: "trash")
                        }
                    }
                    if recordingService.isRecording {
                        Button {
                            if let data = recordingService.stopRecording() {
                                viewModel.recordedAudioData = data
                            }
                        } label: {
                            Label("Stop Recording", systemImage: "stop.circle.fill")
                                .foregroundStyle(.red)
                        }
                    } else {
                        Button {
                            startRecording()
                        } label: {
                            Label(
                                viewModel.recordedAudioData == nil
                                    ? "Record Your Voice"
                                    : "Record Again",
                                systemImage: "mic.fill"
                            )
                        }
                    }
                    if micPermissionDenied {
                        Text("Microphone access is off. Enable it in iPad Settings → Privacy → Microphone.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Voice")
                } footer: {
                    Text("Record yourself saying the word and the tile will play your voice instead of the synthesised one.")
                }

                Section {
                    Toggle("Hidden from child", isOn: $viewModel.isHidden)
                } footer: {
                    Text("Hidden words keep their place on the board and can be shown again when your child is ready.")
                }

                Section("Colour") {
                    Picker("Tile colour", selection: $viewModel.tileColor) {
                        ForEach(TileColor.allCases, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(color.accent)
                                    .frame(width: 22, height: 22)
                                Text(color.displayName)
                            }
                            .tag(color)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
            }
            .navigationTitle(isEditing ? "Edit Icon" : "New Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save(in: context, categories: categories)
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .onChange(of: photoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        viewModel.setPhoto(data)
                    }
                    photoItem = nil
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { data in
                    viewModel.setPhoto(data)
                }
                .ignoresSafeArea()
            }
            .onDisappear {
                recordingService.cancelRecording()
            }
        }
    }

    private func startRecording() {
        Task {
            guard await recordingService.requestPermission() else {
                micPermissionDenied = true
                return
            }
            micPermissionDenied = false
            speech.stop()
            try? recordingService.startRecording()
        }
    }
}
