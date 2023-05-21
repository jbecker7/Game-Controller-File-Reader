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

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .horizontal
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(url: url)
        uiView.usePageViewController(true, withViewOptions: [UIPageViewController.OptionsKey.interPageSpacing: 20])
    }
}

struct ContentView: View {
    @State private var importedPDFs: [URL] = []
    @State private var showDocumentPicker = false
    @State private var currentPDFIndex = 0
    @State private var currentController: GCController?

    var body: some View {
        VStack {
            if importedPDFs.isEmpty {
                Text("No PDFs imported")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            } else {
                TabView(selection: $currentPDFIndex) {
                    ForEach(importedPDFs.indices, id: \.self) { index in
                        PDFKitView(url: importedPDFs[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
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
            let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                if self.currentController == nil {
                    self.currentController = GCController.controllers().first
                }
                
                DispatchQueue.main.async {
                    if self.currentController?.extendedGamepad?.dpad.right.isPressed == true {
                        if self.currentPDFIndex < self.importedPDFs.count - 1 {
                            self.currentPDFIndex += 1
                        }
                    } else if self.currentController?.extendedGamepad?.dpad.left.isPressed == true {
                        if self.currentPDFIndex > 0 {
                            self.currentPDFIndex -= 1
                        }
                    }
                }

                self.currentController?.extendedGamepad?.buttonMenu.valueChangedHandler = { (button, value, pressed) in
                    if pressed {
                        self.showDocumentPicker = true
                    }
                }
            }
            timer.tolerance = 0.05
            RunLoop.current.add(timer, forMode: .common)
        }
    }
}
