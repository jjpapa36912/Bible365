import Foundation
import AVFoundation

final class Recorder: NSObject, ObservableObject {

    private var audioRecorder: AVAudioRecorder?
    @Published var isRecording = false

    var outputURL: URL? {
        audioRecorder?.url
    }

    func startRecording() {
        print("🎤 [Recorder] startRecording() called")

        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            print("🎤 [Recorder] AVAudioSession configured")

            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("bible-voice-\(UUID().uuidString).wav")
            print("🎤 [Recorder] will record to: \(fileURL.path)")

            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            let ok = audioRecorder?.record() ?? false
            isRecording = ok

            print("🎤 [Recorder] record() started = \(ok)")
        } catch {
            print("❌ [Recorder] startRecording error: \(error)")
        }
    }

    func stopRecording() {
        print("🎤 [Recorder] stopRecording() called")
        guard let rec = audioRecorder else {
            print("⚠️ [Recorder] audioRecorder is nil")
            return
        }

        rec.stop()
        isRecording = false

        print("🎤 [Recorder] stopped. file url = \(rec.url.path)")
        do {
            let data = try Data(contentsOf: rec.url)
            print("🎤 [Recorder] recorded file size = \(data.count) bytes")
        } catch {
            print("⚠️ [Recorder] cannot read recorded file: \(error)")
        }
    }
}
