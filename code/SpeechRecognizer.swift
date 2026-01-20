import Foundation
import Speech
import AVFoundation
import Combine

final class SpeechRecognizer: ObservableObject {
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()

    @Published var partialResult: String = ""
    @Published var finalResult: String = ""

    func startTranscription() {
        finalResult = ""
        partialResult = ""

        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.startRecognitionSession()
                case .denied, .restricted, .notDetermined:
                    print("Autorisation de reconnaissance vocale refusee")
                @unknown default:
                    print("Etat d'autorisation inconnu")
                }
            }
        }
    }

    private func startRecognitionSession() {
        if audioEngine.isRunning {
            stopTranscription()
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                self.partialResult = result.bestTranscription.formattedString
                if result.isFinal {
                    self.finalResult = result.bestTranscription.formattedString
                }
            }

            if let error = error {
                print("Erreur reconnaissance : \(error.localizedDescription)")
                self.stopTranscription()
            }
        }

        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            print("Echec demarrage moteur audio : \(error.localizedDescription)")
        }
    }

    func stopTranscription() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.recognitionTask?.cancel()
            self.recognitionTask = nil
            self.recognitionRequest = nil
        }
    }
}

