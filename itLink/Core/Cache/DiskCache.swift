import Foundation

final class DiskCache: Sendable {
    nonisolated static let shared = DiskCache()

    private nonisolated let rootDirectory: URL

    nonisolated convenience init(fileManager: FileManager = .default) {
        let baseDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        self.init(
            rootDirectory: baseDirectory.appendingPathComponent("itLinkCache", isDirectory: true),
            fileManager: fileManager
        )
    }

    nonisolated init(rootDirectory: URL, fileManager: FileManager = .default) {
        self.rootDirectory = rootDirectory
        try? fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
    }

    nonisolated func write(_ data: Data, fileName: String, subdirectory: String) throws {
        let fileManager = FileManager.default
        let directory = rootDirectory.appendingPathComponent(subdirectory, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: .atomic)
    }

    nonisolated func read(fileName: String, subdirectory: String) -> Data? {
        let fileURL = rootDirectory
            .appendingPathComponent(subdirectory, isDirectory: true)
            .appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }
}
