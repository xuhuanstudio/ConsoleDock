import Foundation

struct ConsoleDockIssueReportFileExporter {
    static func makeTemporaryReportFile(reportText: String, generatedAt: Date = Date()) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ConsoleDockIssueReports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let filename = "ConsoleDock-Issue-Report-\(filenameTimestamp(generatedAt))-\(UUID().uuidString).txt"
        let fileURL = directory.appendingPathComponent(filename, isDirectory: false)
        try reportText.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
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
}
