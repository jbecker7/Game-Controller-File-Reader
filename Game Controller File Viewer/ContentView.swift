import SwiftUI
import UIKit
import PDFKit
import MobileCoreServices
import GameController

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var importedPDFs: [URL]
    @Environment(\.presentationMode) private var presentationMode

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.presentationMode.wrappedValue.dismiss()
            DispatchQueue.main.async {
                self.parent.importedPDFs = urls
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL
    @Binding var currentPage: Int
    @Binding var scale: CGFloat
    @Binding var offset: CGFloat

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .horizontal
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(url: url)
        let page = uiView.document?.page(at: currentPage) ?? PDFPage()
        uiView.go(to: page)
        uiView.scaleFactor = uiView.scaleFactorForSizeToFit * scale
        uiView.go(to: CGRect(x: 0, y: offset, width: 1, height: 1), on: page)
    }
}

struct ContentView: View {
    @State private var importedPDFs: [URL] = []
    @State private var showDocumentPicker = false
    @State private var currentPage = 0
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGFloat = 0.0
    @State private var currentController: GCController?
    @State private var timer: Timer? = nil
    @State private var lastActionTime = Date()

    var body: some View {
        VStack {
            if importedPDFs.isEmpty {
                Text("No PDFs imported")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            } else {
                PDFKitView(url: importedPDFs.first!, currentPage: $currentPage, scale: $scale, offset: $offset)
                    .frame(height: UIScreen.main.bounds.height * 0.7)
            }

            Button(action: {
                showDocumentPicker = true
            }) {
                Image(systemName: "folder")
                    .font(.largeTitle)
            }
            .padding()
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(importedPDFs: $importedPDFs)
            }
        }
        .padding()
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                if self.currentController == nil {
                    self.currentController = GCController.controllers().first

                    self.currentController?.extendedGamepad?.buttonMenu.valueChangedHandler = { (button, value, pressed) in
                        if pressed {
                            self.showDocumentPicker = true
                        }
                    }
                }

                let now = Date()
                if now.timeIntervalSince(self.lastActionTime) > 0.5 {
                    DispatchQueue.main.async {
                        if self.currentController?.extendedGamepad?.dpad.right.isPressed == true {
                            self.currentPage += 1
                            self.lastActionTime = now
                        } else if self.currentController?.extendedGamepad?.dpad.left.isPressed == true {
                            self.currentPage -= 1
                            if self.currentPage < 0 {
                                self.currentPage = 0
                            }
                            self.lastActionTime = now
                        } else if self.currentController?.extendedGamepad?.buttonA.isPressed == true {
                            self.scale *= 1.1
                            self.lastActionTime = now
                        } else if self.currentController?.extendedGamepad?.buttonB.isPressed == true {
                            self.scale /= 1.1
                            self.lastActionTime = now
                        } else if self.currentController?.extendedGamepad?.dpad.up.isPressed == true {
                            self.offset += 50
                            self.lastActionTime = now
                        } else if self.currentController?.extendedGamepad?.dpad.down.isPressed == true {
                            self.offset -= 50
                            self.lastActionTime = now
                        }
                    }
                }
            }
            timer?.tolerance = 0.05
            RunLoop.current.add(timer!, forMode: .common)
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}
