import Foundation
import Speech
import AVFoundation

/// iOS 내장 STT(SFSpeechRecognizer)를 사용하는 실시간 음성 인식 헬퍼
final class SpeechRecognizer: NSObject, ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var isRunning: Bool = false
    @Published var lastText: String = ""

    private let speechRecognizer: SFSpeechRecognizer? =
        SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    override init() {
        super.init()
        speechRecognizer?.delegate = self
    }

    // MARK: - 권한 요청

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.isAuthorized = true
                    print("🎙 [STT] Speech recognition authorized")
                case .denied, .restricted, .notDetermined:
                    self?.isAuthorized = false
                    print("❌ [STT] Speech recognition not authorized: \(status.rawValue)")
                @unknown default:
                    self?.isAuthorized = false
                }
            }
        }
    }

    // MARK: - 시작 / 중지

    /// 실시간으로 인식된 전체 텍스트를 콜백으로 넘겨준다.
    func start(onText: @escaping (String) -> Void) {
        print("🎙 [STT] start() called")

        if isRunning {
            print("🎙 [STT] already running, ignore")
            return
        }

        // 권한 없으면 요청부터
        if !isAuthorized {
            requestAuthorization()
        }

        // 이전 세션 정리
        resetRecognition()

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ [STT] audioSession setCategory/setActive error: \(error)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("❌ [STT] failed to create recognitionRequest")
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("❌ [STT] speechRecognizer not available")
            return
        }

        // recognitionTask 생성
        recognitionTask = recognizer.recognitionTask(
            with: recognitionRequest
        ) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let text = result.bestTranscription.formattedString
                self.lastText = text
                DispatchQueue.main.async {
                    onText(text)
                }
                print("🎙 [STT] partial/final text = \(text)")

                if result.isFinal {
                    print("🎙 [STT] result isFinal, stopping")
                    self.stop()
                }
            }

            if let error = error {
                print("❌ [STT] recognitionTask error: \(error)")
                self.stop()
            }
        }

        // 마이크 입력을 recognitionRequest로 연결
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0,
                             bufferSize: 1024,
                             format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRunning = true
                print("🎙 [STT] audioEngine started")
            }
        } catch {
            print("❌ [STT] audioEngine.start error: \(error)")
        }
    }

    func stop() {
        print("🎙 [STT] stop() called")

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()

        resetRecognition()

        DispatchQueue.main.async {
            self.isRunning = false
        }
    }

    private func resetRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
}

extension SpeechRecognizer: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        print("🎙 [STT] availabilityDidChange = \(available)")
    }
}
