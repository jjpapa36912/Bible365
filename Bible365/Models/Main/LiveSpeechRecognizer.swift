//
//  LiveSpeechRecognizer.swift
//  Bible365
//
//  Created by 김동준 on 11/25/25.
//

import Foundation
import Foundation
import Speech
import AVFoundation

final class LiveSpeechRecognizer: NSObject, ObservableObject {
    @Published var recognizedText: String = ""   // 실시간 인식 결과 전체
    @Published var isRunning: Bool = false

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func requestAuthorizationIfNeeded() {
        SFSpeechRecognizer.requestAuthorization { status in
            print("🎤 [LiveSTT] auth status = \(status.rawValue)")
        }
    }

    func start() {
        guard !audioEngine.isRunning else { return }

        recognizedText = ""
        isRunning = true

        request = SFSpeechAudioBufferRecognitionRequest()
        request?.shouldReportPartialResults = true

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ [LiveSTT] AVAudioSession error: \(error)")
            return
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, when in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("🎤 [LiveSTT] audioEngine started")
        } catch {
            print("❌ [LiveSTT] audioEngine start error: \(error)")
            return
        }

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("❌ [LiveSTT] recognizer not available")
            return
        }

        recognitionTask = recognizer.recognitionTask(with: request!) { [weak self] result, error in
            if let result = result {
                // 여기서 partial / final 결과 실시간으로 들어옴
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self?.recognizedText = text
                }
            }

            if let error = error {
                print("❌ [LiveSTT] recognition error: \(error)")
            }

            if let result = result, result.isFinal {
                print("✅ [LiveSTT] final result: \(result.bestTranscription.formattedString)")
            }
        }
    }

    func stop() {
        guard audioEngine.isRunning else { return }

        isRunning = false
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("❌ [LiveSTT] setActive(false) error: \(error)")
        }

        print("🎤 [LiveSTT] stopped")
    }
}
