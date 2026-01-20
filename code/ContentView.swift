import SwiftUI
import AppKit

struct ContentView: View {

    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var isListening = false

    @State private var userText = ""
    @State private var selectedRange = NSRange(location: 0, length: 0)

    @State private var previewText = ""
    @State private var textViewRef: NSTextView? = nil
    
    @State private var editorFontSize: CGFloat = 20

    var body: some View {
        
        

        VStack(spacing: 24) {
            Slider(value: $editorFontSize, in: 10...24, step: 1)
                .frame(maxWidth: 300)

            Text("Police : \(Int(editorFontSize))")
                .frame(maxWidth: 300)
                .padding()

            Text("Parler pour transformer en texte (macOS)")
                .font(.headline)


            // Editeur multilignes
            MacTextView(
                text: $userText,
                selectedRange: $selectedRange,
                fontSize: editorFontSize
            ) { tv in
                self.textViewRef = tv
            }
            .frame(minHeight: 240)
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            

            // Previsualisation live (pendant l'ecoute)
            Group {
                if isListening {
                    Text(previewText.isEmpty ? "Ecoute en cours..." : previewText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.gray.opacity(0.10))
                        .cornerRadius(10)
                        .textSelection(.enabled)
                        .font(.title)
                }
            }

            HStack(spacing: 12) {

                Button(isListening ? "Stop" : "Start") {
                    if isListening {
                        speechRecognizer.stopTranscription()
                        isListening = false

                        let spoken = !speechRecognizer.finalResult.isEmpty
                            ? speechRecognizer.finalResult
                            : speechRecognizer.partialResult

                        if !spoken.isEmpty {
                            // Selection/caret AU MOMENT DU STOP (vous pouvez encore la changer pendant l'ecoute)
                            let realSelection = textViewRef?.selectedRange() ?? selectedRange
                            insert(spoken, at: realSelection)
                        }

                        previewText = ""

                        // Optionnel : remettre le focus dans l'editeur
                        textViewRef?.window?.makeFirstResponder(textViewRef)

                    } else {
                        previewText = ""
                        speechRecognizer.startTranscription()
                        isListening = true
                    }
                }
                .foregroundColor(isListening ? .red : .blue)

                Button("Clear") {
                    userText = ""
                    selectedRange = NSRange(location: 0, length: 0)
                    previewText = ""
                    speechRecognizer.partialResult = ""
                    speechRecognizer.finalResult = ""
                }
                .disabled(isListening)
            }
        }
        .padding()
        .onReceive(speechRecognizer.$partialResult) { partial in
            guard isListening else { return }
            previewText = partial
        }
    }

    private func insert(_ insertion: String, at range: NSRange) {
        let ns = userText as NSString
        let safeLoc = max(0, min(range.location, ns.length))
        let safeLen = max(0, min(range.length, ns.length - safeLoc))
        let safeRange = NSRange(location: safeLoc, length: safeLen)

        userText = ns.replacingCharacters(in: safeRange, with: insertion)

        let newCaret = safeLoc + (insertion as NSString).length
        selectedRange = NSRange(location: newCaret, length: 0)
    }
}

