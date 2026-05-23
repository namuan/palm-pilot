import Foundation

enum LogLevel: String, Comparable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        let order: [LogLevel] = [.debug, .info, .warning, .error]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

final class AppLogger {
    static let shared = AppLogger()

    var minimumLevel: LogLevel = .debug

    private let queue = DispatchQueue(label: "com.palmpilot.logger", qos: .utility)
    private let timestampFormatter: DateFormatter
    private let fileDateFormatter: DateFormatter
    private let logDir: URL
    private var currentFile: URL
    private var currentSize: UInt64 = 0
    private let maxFileSize: UInt64 = 1_048_576
    private let maxLogFiles = 5

    private init() {
        timestampFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            f.locale = Locale(identifier: "en_US_POSIX")
            return f
        }()
        fileDateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f
        }()

        let baseDir = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Logs")
            .appendingPathComponent("Palm Pilot")
        logDir = baseDir

        let stamp = fileDateFormatter.string(from: Date())
        currentFile = baseDir.appendingPathComponent("palm-pilot-\(stamp).log")

        try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        writeLine("--- Log opened \(timestampFormatter.string(from: Date())) ---")
        writeLine("--- Log directory: \(baseDir.path) ---")
    }

    // MARK: - Public API

    func debug(_ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) {
        guard minimumLevel <= .debug else { return }
        write(.debug, message(), file: file, line: line, function: function)
    }

    func info(_ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) {
        guard minimumLevel <= .info else { return }
        write(.info, message(), file: file, line: line, function: function)
    }

    func warning(_ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) {
        guard minimumLevel <= .warning else { return }
        write(.warning, message(), file: file, line: line, function: function)
    }

    func error(_ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) {
        guard minimumLevel <= .error else { return }
        write(.error, message(), file: file, line: line, function: function)
    }

    // MARK: - Internal

    private func write(_ level: LogLevel, _ message: String, file: StaticString, line: UInt, function: StaticString) {
        let sourceFile = (String(describing: file) as NSString).lastPathComponent
        let timestamp = timestampFormatter.string(from: Date())
        let logLine = "\(timestamp) [\(level.rawValue)] \(sourceFile):\(line) \(function) > \(message)"

        queue.async { [weak self] in
            self?.writeLine(logLine)
        }
    }

    private func writeLine(_ line: String) {
        let payload = line + "\n"
        guard let data = payload.data(using: .utf8) else { return }

        if currentSize >= maxFileSize {
            rotate()
        }

        if FileManager.default.fileExists(atPath: currentFile.path) {
            guard let handle = try? FileHandle(forWritingTo: currentFile) else { return }
            handle.seekToEndOfFile()
            handle.write(data)
            handle.closeFile()
        } else {
            try? data.write(to: currentFile, options: .atomic)
        }
        currentSize += UInt64(data.count)
    }

    private func rotate() {
        var existing = (try? FileManager.default.contentsOfDirectory(at: logDir, includingPropertiesForKeys: nil))
            ?? []
            .filter { $0.lastPathComponent.hasPrefix("palm-pilot-") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        while existing.count >= maxLogFiles {
            try? FileManager.default.removeItem(at: existing.removeFirst())
        }

        let stamp = fileDateFormatter.string(from: Date())
        let suffix = existing.count + 1
        currentFile = logDir.appendingPathComponent("palm-pilot-\(stamp)-\(suffix).log")
        currentSize = 0
    }
}

let Log = AppLogger.shared
