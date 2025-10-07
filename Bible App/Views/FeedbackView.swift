import SwiftUI
import PhotosUI
import Photos

struct FeedbackView: View {
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var images: [UIImage] = []
    @State private var showingPicker: Bool = false
    @State private var isSending: Bool = false
    @State private var showSentToast: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("We value your feedback")
                    .font(.title2).bold()

                TextField("Short title (what’s the issue?)", text: $title)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Describe the problem")
                        .font(.subheadline).foregroundColor(.secondary)
                    TextEditor(text: $description)
                        .frame(minHeight: 160)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Screenshots / photos")
                            .font(.subheadline).foregroundColor(.secondary)
                        Spacer()
                        Button(action: { showingPicker = true }) {
                            Label("Add", systemImage: "plus")
                        }
                    }
                    if images.isEmpty == false {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(images.enumerated()), id: \.offset) { idx, img in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipped()
                                            .cornerRadius(10)
                                        Button(action: { images.remove(at: idx) }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .shadow(radius: 2)
                                        }
                                        .padding(6)
                                    }
                                }
                            }
                        }
                    }
                }

                Button(action: send) {
                    HStack {
                        Spacer()
                        if isSending { ProgressView().tint(.white) } else { Text("Send Feedback").bold() }
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSending || title.trimmingCharacters(in: .whitespaces).isEmpty || description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(16)
        }
        .navigationTitle("Feedback")
        .sheet(isPresented: $showingPicker) { ImagePicker(images: $images) }
        .overlay(alignment: .top) {
            if showSentToast {
                Text("Thanks! Feedback sent.")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func send() {
        isSending = true
        Task {
            let ok = await FeedbackService.shared.sendFeedback(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                images: images
            )
            await MainActor.run {
                isSending = false
                withAnimation { showSentToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { withAnimation { showSentToast = false } }
                if ok { title = ""; description = ""; images.removeAll() }
            }
        }
    }
}

private struct FeedbackPayload: Codable { let title: String; let description: String; let imagesBase64: [String] }

// Simple multi-select image picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]

    func makeCoordinator() -> Coord { Coord(self) }

    func makeUIViewController(context: Context) -> some UIViewController {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.filter = .images
        config.selectionLimit = 0
        let vc = PHPickerViewController(configuration: config)
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    final class Coord: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            for item in results {
                if item.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    item.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                        if let img = obj as? UIImage {
                            DispatchQueue.main.async { self.parent.images.append(img) }
                        }
                    }
                }
            }
        }
    }
}


