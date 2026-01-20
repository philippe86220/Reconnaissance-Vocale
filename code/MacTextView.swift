
import SwiftUI
import AppKit

struct MacTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var selectedRange: NSRange
    var fontSize: CGFloat = 14
    var onTextViewReady: ((NSTextView) -> Void)? = nil


    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false

        let tv = NSTextView()
        tv.isEditable = true
        tv.isSelectable = true
        tv.isRichText = false
        tv.drawsBackground = false
        tv.allowsUndo = true
        tv.font = NSFont.systemFont(ofSize: fontSize)
        tv.delegate = context.coordinator

        tv.isHorizontallyResizable = false
        tv.isVerticallyResizable = true
        tv.textContainer?.widthTracksTextView = true
        tv.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)

        tv.string = text
        tv.setSelectedRange(selectedRange)

        scrollView.documentView = tv

        DispatchQueue.main.async { self.onTextViewReady?(tv) }
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let tv = nsView.documentView as? NSTextView else { return }

        if tv.string != text {
            tv.string = text
        }
        
        if let f = tv.font, f.pointSize != fontSize {
            tv.font = NSFont.systemFont(ofSize: fontSize)
        }

        // Ne pas forcer la selection si l'utilisateur est en train de taper (focus sur le NSTextView)
        let isEditing = (tv.window?.firstResponder === tv)

        if !isEditing {
            let cur = tv.selectedRange()
            if cur.location != selectedRange.location || cur.length != selectedRange.length {
                tv.setSelectedRange(selectedRange)
            }
        }
    }


    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, selectedRange: $selectedRange)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        @Binding var selectedRange: NSRange

        init(text: Binding<String>, selectedRange: Binding<NSRange>) {
            _text = text
            _selectedRange = selectedRange
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            text = tv.string
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            let r = tv.selectedRange()
            DispatchQueue.main.async {
                self.selectedRange = r
            }
        }
    }
}

