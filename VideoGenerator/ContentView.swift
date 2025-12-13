import SwiftUI
#if os(macOS)
import AppKit
#endif

// Simple reference image wrapper
struct ReferenceImage: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    #if os(macOS)
    var image: NSImage
    #else
    var image: UIImage
    #endif
}

extension ReferenceImage {
    #if os(macOS)
    var swiftUIImage: Image { Image(nsImage: image) }
    #else
    var swiftUIImage: Image { Image(uiImage: image) }
    #endif
}

struct ContentView: View {
    // Core state
    @StateObject private var videoGenerator = MetalVideoGenerator()
    @EnvironmentObject private var modelManager: ModelManager

    // UI state
    @State private var prompt: String = ""
    @State private var attachments: [ReferenceImage] = []
    @State private var isGenerating = false
    @State private var status: String = "Ready"
    @State private var showAlert = false
    @State private var showingImporter = false
    @State private var dropHighlight = false

    var body: some View {
        VStack(spacing: 18) {
            promptEditor
            attachmentStrip
            modelPicker
            actionRow
            statusRow
        }
        .padding(24)
        .frame(minWidth: 640, minHeight: 520)
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.image], allowsMultipleSelection: true, onCompletion: handleImport)
        .alert("Video", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text(status) }
    }
}

// MARK: - Sections
private extension ContentView {
    var promptEditor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $prompt)
                .font(.system(size: 15))
                .padding(12)
                .frame(minHeight: 200)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.25)))
            if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Enter prompt…")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
            }
        }
        .accessibilityLabel("Prompt Editor")
    }

    var attachmentStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text("Images").font(.headline)
                Spacer()
                if !attachments.isEmpty {
                    Button("Clear") { attachments.removeAll(); status = "Cleared images" }
                        .buttonStyle(.bordered)
                }
                Button { showingImporter = true } label: { Label("Add", systemImage: "plus") }
                    .buttonStyle(.bordered)
            }
            if attachments.isEmpty { dropZone } else { thumbnails }
        }
    }

    var dropZone: some View {
        VStack(spacing: 6) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 40))
                .foregroundColor(dropHighlight ? .accentColor : .secondary)
            Text("Drag & drop images here or click Add")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(dropHighlight ? Color.accentColor : Color.secondary.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [6]))
        )
        .background(dropHighlight ? Color.accentColor.opacity(0.07) : Color.clear)
        .onDrop(of: [.fileURL], isTargeted: $dropHighlight) { providers in
            handleDrop(providers)
        }
    }

    var thumbnails: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(Array(attachments.enumerated()), id: \.element.id) { _, item in
                    ZStack(alignment: .topTrailing) {
                        item.swiftUIImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Button {
                            attachments.removeAll { $0.id == item.id }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .red)
                        }
                        .buttonStyle(.plain)
                        .padding(4)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var modelPicker: some View {
        Group {
            if !modelManager.models.isEmpty {
                Picker("Model", selection: $modelManager.selectedModelID) {
                    ForEach(modelManager.models) { model in
                        Text(model.name).tag(model.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 240)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    var actionRow: some View {
        HStack(spacing: 12) {
            Button(action: generate) {
                HStack(spacing: 8) {
                    if isGenerating { ProgressView().progressViewStyle(.circular) }
                    Text(isGenerating ? "Generating…" : "Generate")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isGenerating || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            #if os(macOS)
            if let url = videoGenerator.lastOutputURL {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                } label: { Label("Reveal", systemImage: "folder") }
                    .buttonStyle(.bordered)
            }
            #endif
        }
    }

    var statusRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(status).font(.caption).foregroundColor(.secondary)
            if let url = videoGenerator.lastOutputURL {
                Text(url.lastPathComponent)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Actions & Helpers
private extension ContentView {
    func generate() {
        isGenerating = true
        status = "Preparing model…"
        let refs = attachments.map { $0.url }
        Task {
            do {
                let output = try await videoGenerator.generateVideo(model: modelManager.selectedModel, prompt: prompt, referenceImages: refs)
                await MainActor.run {
                    status = "Saved: \(output.lastPathComponent)"
                    isGenerating = false
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    status = "Failed: \(error.localizedDescription)"
                    isGenerating = false
                    showAlert = true
                }
            }
        }
    }

    func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls): appendImages(urls)
        case .failure(let err): status = "Import error: \(err.localizedDescription)"
        }
    }

    func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var loaded = false
        for p in providers {
            if p.canLoadObject(ofClass: URL.self) {
                _ = p.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url { DispatchQueue.main.async { appendImages([url]) } }
                }
                loaded = true
            }
        }
        return loaded
    }

    func appendImages(_ urls: [URL]) {
        for u in urls {
            #if os(macOS)
            if let img = NSImage(contentsOf: u) {
                if !attachments.contains(where: { $0.url == u }) { attachments.append(.init(url: u, image: img)) }
            }
            #else
            if let data = try? Data(contentsOf: u), let img = UIImage(data: data) {
                if !attachments.contains(where: { $0.url == u }) { attachments.append(.init(url: u, image: img)) }
            }
            #endif
        }
        status = "Loaded \(attachments.count) image\(attachments.count == 1 ? "" : "s")"
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(ModelManager())
    }
}
