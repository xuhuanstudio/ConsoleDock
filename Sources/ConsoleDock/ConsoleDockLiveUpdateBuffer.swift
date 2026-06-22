import Foundation

struct ConsoleDockLiveUpdateBuffer {
    private(set) var displayedEntries: [ConsoleDock.LogEntry] = []
    private var pendingEntries: [ConsoleDock.LogEntry]?
    private(set) var isPaused = false

    mutating func receive(snapshot: [ConsoleDock.LogEntry]) -> Bool {
        if isPaused {
            pendingEntries = snapshot
            return false
        }

        displayedEntries = snapshot
        return true
    }

    mutating func pause() {
        isPaused = true
        pendingEntries = nil
    }

    mutating func resume(latestEntries: [ConsoleDock.LogEntry]) {
        isPaused = false
        displayedEntries = pendingEntries ?? latestEntries
        pendingEntries = nil
    }

    mutating func replaceDisplayedEntries(_ entries: [ConsoleDock.LogEntry]) {
        displayedEntries = entries
        pendingEntries = nil
    }
}
