import SwiftUI
import UIKit
import MobileCoreServices

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var importedImages: [UIImage]
    @Environment(\.presentationMode) private var presentationMode

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.image], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true // Enable multiple image selection
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
            for url in urls {
                if let image = UIImage(contentsOfFile: url.path) {
                    DispatchQueue.main.async {
                        self.parent.importedImages.append(image)
                    }
                }
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ContentView: View {
    @State private var importedImages: [UIImage] = []
    @State private var showDocumentPicker = false

    var body: some View {
        VStack {
            if importedImages.isEmpty {
                Text("No images imported")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            } else {
                TabView {
                    ForEach(importedImages.indices, id: \.self) { index in
                        Image(uiImage: importedImages[index])
                            .resizable()
                            .scaledToFit()
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
                DocumentPicker(importedImages: $importedImages)
            }
        }
        .padding()
    }
}

