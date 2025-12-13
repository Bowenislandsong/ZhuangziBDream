import Foundation
import UniformTypeIdentifiers

// Represents a downloadable or bundled model file
struct Model: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let filename: String
    let isBundled: Bool
    let fileSize: Int64?
    let addedAt: Date
    let sourceURL: URL?
}

enum ModelManagerError: LocalizedError {
    case invalidDownloadURL
    case downloadFailed
    case fileMoveFailed
    case modelAlreadyExists

    var errorDescription: String? {
        switch self {
        case .invalidDownloadURL: return "The provided URL is invalid."
        case .downloadFailed: return "Failed to download model file."
        case .fileMoveFailed: return "Failed to store downloaded model file."
        case .modelAlreadyExists: return "A model with the same filename already exists."
        }
    }
}

@MainActor
class ModelManager: ObservableObject {
    @Published private(set) var models: [Model] = []
    @Published var selectedModelID: UUID? {
        didSet { persistSelection() }
    }

    private let bundledModelsFolderName = "Models"
    private let persistenceKey = "modelManager.models"
    private let selectionKey = "modelManager.selectedModelID"
    private let fileManager = FileManager.default

    var selectedModel: Model? { models.first(where: { $0.id == selectedModelID }) }

    init() {
        Task { await load() }
    }

    // Public API
    func addModel(fromRemoteURL remoteURL: URL) async throws -> Model {
        // Basic validation
        guard ["http", "https"].contains(remoteURL.scheme?.lowercased()) else {
            throw ModelManagerError.invalidDownloadURL
        }

        let (tempLocalURL, response) = try await URLSession.shared.download(from: remoteURL)
        guard let httpResp = response as? HTTPURLResponse, (200..<300).contains(httpResp.statusCode) else {
            throw ModelManagerError.downloadFailed
        }

        let filename = remoteURL.lastPathComponent
        let destinationURL = userModelsDirectory().appendingPathComponent(filename)
        if fileManager.fileExists(atPath: destinationURL.path) {
            throw ModelManagerError.modelAlreadyExists
        }

        try fileManager.createDirectory(at: userModelsDirectory(), withIntermediateDirectories: true)
        do {
            try fileManager.moveItem(at: tempLocalURL, to: destinationURL)
        } catch {
            throw ModelManagerError.fileMoveFailed
        }

        let fileSize = (try? destinationURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) }
        let model = Model(
            id: UUID(),
            name: prettifyName(filename: filename),
            filename: filename,
            isBundled: false,
            fileSize: fileSize,
            addedAt: Date(),
            sourceURL: remoteURL
        )
        models.append(model)
        persist()
        if selectedModelID == nil { selectedModelID = model.id }
        return model
    }

    // Load & persistence
    private func loadBundledModels() {
        guard let bundleURL = Bundle.main.resourceURL?.appendingPathComponent(bundledModelsFolderName) else { return }
        guard let files = try? fileManager.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else { return }
        let bundled: [Model] = files.map { url in
            let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) }
            return Model(
                id: UUID(),
                name: prettifyName(filename: url.lastPathComponent),
                filename: url.lastPathComponent,
                isBundled: true,
                fileSize: fileSize,
                addedAt: Date(),
                sourceURL: nil
            )
        }.sorted { $0.name < $1.name }

        // Only add bundled models that are not already persisted by filename
        let existingFilenames = Set(models.map { $0.filename })
        let newOnes = bundled.filter { !existingFilenames.contains($0.filename) }
        if !newOnes.isEmpty {
            models.append(contentsOf: newOnes)
        }
    }

    private func copyBundledModelsToUserDirectoryIfNeeded() {
        guard let bundleURL = Bundle.main.resourceURL?.appendingPathComponent(bundledModelsFolderName) else { return }
        guard let files = try? fileManager.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { return }
        let destDir = userModelsDirectory()
        try? fileManager.createDirectory(at: destDir, withIntermediateDirectories: true)
        for src in files {
            let dst = destDir.appendingPathComponent(src.lastPathComponent)
            if !fileManager.fileExists(atPath: dst.path) {
                _ = try? fileManager.copyItem(at: src, to: dst)
            }
        }
    }

    private func loadPersisted() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else { return }
        if let decoded = try? JSONDecoder().decode([Model].self, from: data) {
            models = decoded
        }
        if let selID = UserDefaults.standard.string(forKey: selectionKey), let uuid = UUID(uuidString: selID) {
            selectedModelID = uuid
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(models) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private func persistSelection() {
        if let sel = selectedModelID {
            UserDefaults.standard.set(sel.uuidString, forKey: selectionKey)
        }
    }

    private func load() async {
        loadPersisted()
        loadBundledModels()
        copyBundledModelsToUserDirectoryIfNeeded()
        if selectedModelID == nil {
            selectedModelID = models.first?.id
        }
    }

    // Helpers
    private func userModelsDirectory() -> URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = appSupport.appendingPathComponent("UserModels", isDirectory: true)
        return dir
    }

    // Resolve a file URL for a given model: prefer the user directory copy, fall back to bundle
    func url(for model: Model) -> URL? {
        let userURL = userModelsDirectory().appendingPathComponent(model.filename)
        if fileManager.fileExists(atPath: userURL.path) {
            return userURL
        }
        if let bundleURL = Bundle.main.resourceURL?.appendingPathComponent(bundledModelsFolderName).appendingPathComponent(model.filename),
           fileManager.fileExists(atPath: bundleURL.path) {
            return bundleURL
        }
        return nil
    }

    private func prettifyName(filename: String) -> String {
        filename
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: ".").first.map(String.init) ?? filename
    }
}
