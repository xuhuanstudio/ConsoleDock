import Foundation

final class ConsoleDockSessionArchiveStore {
    static var shared = ConsoleDockSessionArchiveStore()

    private let directoryURL: URL
    private let maximumArchives: Int
    private let maximumReportCharacterCount: Int
    private let fileManager: FileManager
    private let dateProvider: () -> Date
    private let uuidProvider: () -> UUID
    private let lock = NSLock()

    init(
        directoryURL: URL? = nil,
        maximumArchives: Int = 5,
        maximumReportCharacterCount: Int = 256_000,
        fileManager: FileManager = .default,
        dateProvider: @escaping () -> Date = Date.init,
        uuidProvider: @escaping () -> UUID = UUID.init
    ) {
        self.fileManager = fileManager
        self.directoryURL = directoryURL ?? Self.defaultDirectoryURL(fileManager: fileManager)
        self.maximumArchives = max(1, maximumArchives)
        self.maximumReportCharacterCount = max(512, maximumReportCharacterCount)
        self.dateProvider = dateProvider
        self.uuidProvider = uuidProvider
    }

    func save(
        reportText: String,
        metadata: ConsoleDock.SessionMetadata,
        diagnostics: ConsoleDock.Diagnostics,
        note: String?
    ) throws -> ConsoleDock.SessionArchive {
        try withLock {
            try ensureDirectoryExists()

            let createdAt = dateProvider()
            let originalCharacterCount = reportText.count
            let archivedReportText = truncatedReportText(reportText)
            let archive = ConsoleDock.SessionArchive(
                id: uuidProvider().uuidString,
                createdAt: createdAt,
                sourceSessionIdentifier: metadata.sessionIdentifier,
                sourceSessionStartedAt: metadata.startedAt,
                title: "Session \(ConsoleDockSnapshotFormatter.timestampText(createdAt))",
                note: normalizedNote(note),
                entryCount: diagnostics.entryCount,
                reportCharacterCount: originalCharacterCount,
                isReportTruncated: archivedReportText.count < originalCharacterCount,
                reportText: archivedReportText
            )

            try writeRecord(SessionArchiveRecord(archive: archive))
            try pruneArchivesIfNeeded(keeping: archive.id)
            return archive
        }
    }

    func archives() throws -> [ConsoleDock.SessionArchive] {
        try withLock {
            try archiveRecords()
                .map(\.archive)
                .sorted(by: Self.newestFirst)
        }
    }

    func deleteArchive(id: String) throws {
        try withLock {
            let url = fileURL(for: id)
            guard fileManager.fileExists(atPath: url.path) else { return }
            try fileManager.removeItem(at: url)
        }
    }

    func clearArchives() throws {
        try withLock {
            guard fileManager.fileExists(atPath: directoryURL.path) else { return }
            let urls = try archiveFileURLs()
            for url in urls {
                try fileManager.removeItem(at: url)
            }
        }
    }

    private func withLock<T>(_ work: () throws -> T) throws -> T {
        lock.lock()
        defer { lock.unlock() }
        return try work()
    }

    private func ensureDirectoryExists() throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    private func archiveRecords() throws -> [SessionArchiveRecord] {
        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return []
        }

        return try archiveFileURLs().compactMap { url in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(SessionArchiveRecord.self, from: data)
        }
    }

    private func archiveFileURLs() throws -> [URL] {
        try fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension == "json" }
    }

    private func writeRecord(_ record: SessionArchiveRecord) throws {
        let data = try encoder.encode(record)
        try data.write(to: fileURL(for: record.id), options: [.atomic])
    }

    private func pruneArchivesIfNeeded(keeping savedArchiveID: String) throws {
        let records = try archiveRecords().sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.id > rhs.id
            }
            return lhs.createdAt > rhs.createdAt
        }
        guard records.count > maximumArchives else { return }

        for record in records.dropFirst(maximumArchives) where record.id != savedArchiveID {
            let url = fileURL(for: record.id)
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        }
    }

    private func fileURL(for id: String) -> URL {
        directoryURL.appendingPathComponent(sanitizedArchiveID(id), isDirectory: false)
            .appendingPathExtension("json")
    }

    private func sanitizedArchiveID(_ id: String) -> String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-")
        let scalars = id.unicodeScalars.map { scalar -> Character in
            allowed.contains(scalar) ? Character(scalar) : "-"
        }
        let sanitized = String(scalars).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return sanitized.isEmpty ? UUID().uuidString : sanitized
    }

    private func truncatedReportText(_ reportText: String) -> String {
        guard reportText.count > maximumReportCharacterCount else {
            return reportText
        }

        let notice =
            "\n\n[ConsoleDock archive truncated at \(maximumReportCharacterCount) characters. Share the live issue report before clearing logs when full detail is required.]"
        let prefixCount = max(0, maximumReportCharacterCount - notice.count)
        return String(reportText.prefix(prefixCount)) + notice
    }

    private func normalizedNote(_ note: String?) -> String? {
        guard let note else { return nil }
        let normalized =
            note
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }
        return String(normalized.prefix(512))
    }

    private static func newestFirst(
        _ lhs: ConsoleDock.SessionArchive,
        _ rhs: ConsoleDock.SessionArchive
    ) -> Bool {
        if lhs.createdAt == rhs.createdAt {
            return lhs.id > rhs.id
        }
        return lhs.createdAt > rhs.createdAt
    }

    private static func defaultDirectoryURL(fileManager: FileManager) -> URL {
        let baseURL =
            fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let applicationDirectory = Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName
        return
            baseURL
            .appendingPathComponent(applicationDirectory, isDirectory: true)
            .appendingPathComponent("ConsoleDock", isDirectory: true)
            .appendingPathComponent("SessionArchives", isDirectory: true)
    }

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private let decoder = JSONDecoder()
}

private struct SessionArchiveRecord: Codable {
    let id: String
    let createdAt: Date
    let sourceSessionIdentifier: String
    let sourceSessionStartedAt: Date?
    let title: String
    let note: String?
    let entryCount: Int
    let reportCharacterCount: Int
    let isReportTruncated: Bool
    let reportText: String

    init(archive: ConsoleDock.SessionArchive) {
        id = archive.id
        createdAt = archive.createdAt
        sourceSessionIdentifier = archive.sourceSessionIdentifier
        sourceSessionStartedAt = archive.sourceSessionStartedAt
        title = archive.title
        note = archive.note
        entryCount = archive.entryCount
        reportCharacterCount = archive.reportCharacterCount
        isReportTruncated = archive.isReportTruncated
        reportText = archive.reportText
    }

    var archive: ConsoleDock.SessionArchive {
        ConsoleDock.SessionArchive(
            id: id,
            createdAt: createdAt,
            sourceSessionIdentifier: sourceSessionIdentifier,
            sourceSessionStartedAt: sourceSessionStartedAt,
            title: title,
            note: note,
            entryCount: entryCount,
            reportCharacterCount: reportCharacterCount,
            isReportTruncated: isReportTruncated,
            reportText: reportText
        )
    }
}
