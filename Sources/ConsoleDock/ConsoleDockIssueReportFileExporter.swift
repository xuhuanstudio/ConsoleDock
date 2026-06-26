import Foundation

struct ConsoleDockIssueReportFileExporter {
    static func makeTemporaryReportFile(reportText: String, generatedAt: Date = Date()) throws -> URL {
        try makeTemporaryTextFile(
            text: reportText,
            directoryName: "ConsoleDockIssueReports",
            filenamePrefix: "ConsoleDock-Issue-Report",
            generatedAt: generatedAt
        )
    }

    static func makeTemporarySupportReportFile(reportText: String, generatedAt: Date = Date()) throws -> URL {
        try makeTemporaryTextFile(
            text: reportText,
            directoryName: "ConsoleDockSupportReports",
            filenamePrefix: "ConsoleDock-Support-Report",
            generatedAt: generatedAt
        )
    }

    private static func makeTemporaryTextFile(
        text: String,
        directoryName: String,
        filenamePrefix: String,
        generatedAt: Date
    ) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(directoryName, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let filename = "\(filenamePrefix)-\(filenameTimestamp(generatedAt))-\(UUID().uuidString).txt"
        let fileURL = directory.appendingPathComponent(filename, isDirectory: false)
        try text.write(to: fileURL, atomically: true, encoding: .utf8)
        pruneTemporaryTextFiles(in: directory, filenamePrefix: filenamePrefix, protectedFileURL: fileURL)
        return fileURL
    }

    private static func pruneTemporaryTextFiles(
        in directory: URL,
        filenamePrefix: String,
        protectedFileURL: URL
    ) {
        guard
            let fileURLs = try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return
        }

        let reportFileURLs = fileURLs.filter { fileURL in
            fileURL.pathExtension == "txt" && fileURL.lastPathComponent.hasPrefix(filenamePrefix)
        }
        guard reportFileURLs.count > maximumTemporaryTextFileCount else {
            return
        }

        let removableFileURLs = reportFileURLs.filter { $0 != protectedFileURL }
        let sortedNewestFirst = removableFileURLs.sorted { lhs, rhs in
            modificationDate(for: lhs) > modificationDate(for: rhs)
        }
        for fileURL in sortedNewestFirst.dropFirst(maximumTemporaryTextFileCount - 1) {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private static func modificationDate(for fileURL: URL) -> Date {
        let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey])
        return values?.contentModificationDate ?? .distantPast
    }

    private static func filenameTimestamp(_ date: Date) -> String {
        filenameFormatter.string(from: date)
    }

    private static let filenameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        return formatter
    }()

    private static let maximumTemporaryTextFileCount = 20
}
