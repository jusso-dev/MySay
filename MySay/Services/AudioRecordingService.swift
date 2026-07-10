import AVFoundation
import Observation

/// Records a parent's voice for an icon (e.g. Mum saying "drink") so the
/// child can hear a familiar voice instead of the synthesiser.
///
/// Recordings are short AAC/M4A clips stored on the icon itself
/// (`IconItem.recordedAudioData`), so they travel with backups.
@Observable
final class AudioRecordingService {
    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?

    private(set) var isRecording = false

    /// Ask for microphone access. Returns whether recording is allowed.
    @MainActor
    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func startRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mysay-recording-\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.record()
        self.recorder = recorder
        recordingURL = url
        isRecording = true
    }

    /// Stop and return the captured audio, restoring the playback session.
    func stopRecording() -> Data? {
        recorder?.stop()
        recorder = nil
        isRecording = false
        restorePlaybackSession()
        guard let recordingURL else { return nil }
        defer {
            try? FileManager.default.removeItem(at: recordingURL)
            self.recordingURL = nil
        }
        return try? Data(contentsOf: recordingURL)
    }

    func cancelRecording() {
        recorder?.stop()
        recorder = nil
        isRecording = false
        if let recordingURL {
            try? FileManager.default.removeItem(at: recordingURL)
        }
        recordingURL = nil
        restorePlaybackSession()
    }

    private func restorePlaybackSession() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .spokenAudio,
            options: [.duckOthers]
        )
    }
}
