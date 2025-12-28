/// A logger that provides structured logging functionality for ESP-IDF applications.
///
/// The `Logger` class allows logging messages at different severity levels
/// (error, warning, info, debug, verbose, none)
/// and integrates with ESP-IDF's logging system.
/// It supports customizable configuration for formatting, colors, timestamps, and other logging options.
///
/// Example usage:
/// ```swift
/// let logger = Logger(label: "MyApp")
/// logger.info("Application started")
/// logger.error("An error occurred")
///
/// // Custom configuration
/// var config = Logger.Configuration()
/// config.logLevel = .debug
/// let debugLogger = Logger(label: "DebugApp", configuration: config)
/// ```
struct Logger {
    /// The default configuration used for logging when no specific configuration is provided.
    let defaultConfiguration: Configuration

    /// The label used to identify the source of log messages in the output.
    let label: String

    /// Initializes a new logger with the specified label and optional configuration.
    ///
    /// - Parameters:
    ///   - label: A string that identifies the source of log messages.
    ///   - configuration: The default configuration to use for logging. Defaults to a new `Configuration()` instance.
    init(label: String, configuration: Configuration = Configuration()) {
        self.label = label
        self.defaultConfiguration = configuration
    }
}

extension Logger {
    /// Logs a message with the specified configuration.
    ///
    /// This is an internal method that interfaces directly with the ESP-IDF logging shim.
    ///
    /// - Parameters:
    ///   - configuration: The logging configuration to use.
    ///   - message: The message to log.
    private func _log(configuration: Configuration, message: String) {
        shim_esp_log_level_local(configuration.espLogConfig, label, message)
    }

    /// Logs a message at the specified level using the default configuration.
    ///
    /// - Parameters:
    ///   - level: The log level for the message.
    ///   - message: The message to log.
    private func _log(level: Level, message: String) {
        var configuration = defaultConfiguration
        configuration.logLevel = level
        self._log(configuration: configuration, message: message)
    }

    /// Logs a message at the specified level with file, function, and line information.
    ///
    /// This method allows logging with automatic inclusion of context information.
    ///
    /// - Parameters:
    ///   - level: The log level for the message.
    ///   - message: The message parts to log (joined with ", ").
    ///   - file: The file name (automatically provided by #file).
    ///   - function: The function name (automatically provided by #function).
    ///   - line: The line number (automatically provided by #line).
    func log(level: Level, message: String..., file: String = #file, function: String = #function, line: Int = #line) {
        let messageString = "\(message.joined(separator: ", ")) • \(function) \(lastComponent(of: file)):\(line)"
        self._log(level: level, message: messageString)
    }

    /// Logs an error message.
    ///
    /// - Parameters:
    ///   - message: The error message parts to log.
    ///   - file: The file name (automatically provided).
    ///   - function: The function name (automatically provided).
    ///   - line: The line number (automatically provided).
    func error(_ message: String..., file: String = #file, function: String = #function, line: Int = #line) {
        let messageString = "\(message.joined(separator: ", ")) • \(function) \(lastComponent(of: file)):\(line)"
        self._log(level: .error, message: messageString)
    }

    /// Logs a warning message.
    ///
    /// - Parameters:
    ///   - message: The warning message parts to log.
    ///   - file: The file name (automatically provided).
    ///   - function: The function name (automatically provided).
    ///   - line: The line number (automatically provided).
    func warning(_ message: String..., file: String = #file, function: String = #function, line: Int = #line) {
        let messageString = "\(message.joined(separator: ", ")) • \(function) \(lastComponent(of: file)):\(line)"
        self._log(level: .warning, message: messageString)
    }

    /// Logs an informational message.
    ///
    /// - Parameters:
    ///   - message: The informational message parts to log.
    ///   - file: The file name (automatically provided).
    ///   - function: The function name (automatically provided).
    ///   - line: The line number (automatically provided).
    func info(_ message: String..., file: String = #file, function: String = #function, line: Int = #line) {
        let messageString = "\(message.joined(separator: ", ")) • \(function) \(lastComponent(of: file)):\(line)"
        self._log(level: .info, message: messageString)
    }

    /// Logs a debug message.
    ///
    /// - Parameters:
    ///   - message: The debug message parts to log.
    ///   - file: The file name (automatically provided).
    ///   - function: The function name (automatically provided).
    ///   - line: The line number (automatically provided).
    func debug(_ message: String..., file: String = #file, function: String = #function, line: Int = #line) {
        let messageString = "\(message.joined(separator: ", ")) • \(function) \(lastComponent(of: file)):\(line)"
        self._log(level: .debug, message: messageString)
    }

    /// Logs a verbose message.
    ///
    /// - Parameters:
    ///   - message: The verbose message parts to log.
    ///   - file: The file name (automatically provided).
    ///   - function: The function name (automatically provided).
    ///   - line: The line number (automatically provided).
    func verbose(_ message: String..., file: String = #file, function: String = #function, line: Int = #line) {
        let messageString = "\(message.joined(separator: ", ")) • \(function) \(lastComponent(of: file)):\(line)"
        self._log(level: .verbose, message: messageString)
    }
}

extension Logger {
    /// Represents the different logging levels supported by the ESP-IDF logging system.
    ///
    /// These levels correspond to the `esp_log_level_t` enumeration in ESP-IDF.
    enum Level: Int {
        /// No log output.
        case none = 0

        /// Critical errors where the software module cannot recover on its own.
        case error = 1

        /// Error conditions from which recovery measures have been taken.
        case warning = 2

        /// Information messages that describe the normal flow of events.
        case info = 3

        /// Extra information not necessary for normal use (values, pointers, sizes, etc.).
        case debug = 4

        /// Bigger chunks of debugging information or frequent messages that can flood the output.
        case verbose = 5

        /// Number of levels supported. Added for compatibility with `esp_log_level_t`.
        case max = 6

        /// Converts the level to the corresponding C `esp_log_level_t` value.
        var espLevel: esp_log_level_t {
            esp_log_level_t(rawValue: UInt32(self.rawValue))
        }
    }
}

extension Logger {

    /// Configuration options for the logger.
    ///
    /// This struct allows customization of logging behavior, including level, formatting options,
    /// and environment-specific settings.
    struct Configuration {
        /// The log level to use for this configuration.
        var logLevel: Logger.Level = .error

        /// Flag indicating if logging is from a constrained environment
        /// (e.g., bootloader, ISR, startup code, early log, or when the cache is disabled).
        /// In such cases, `esp_rom_vprintf` is used instead of `vprintf`.
        var constrainedEnvironment: Bool = false

        /// Flag specifying whether the log message needs additional formatting.
        /// If set, `esp_log()` will add formatting elements like color, timestamp, and tag to the log message.
        var requireFormatting: Bool = true

        /// Flag to disable color in log output.
        /// If set, log messages will not include color codes.
        var disableColor: Bool = ESP_LOG_COLOR_DISABLED != 0

        /// Flag to disable timestamps in log output.
        /// If set, log messages will not include timestamps.
        var disableTimestamp: Bool = ESP_LOG_TIMESTAMP_DISABLED != 0

        /// Flag to indicate binary mode.
        var binaryMode: Bool = true

        /// Reserved for future use. Should be initialized to 0.
        var reserved: Int = 0

        /// The raw bit-packed representation of the configuration.
        private var raw: UInt32 {
            var value: UInt32 = 0
            value |= UInt32(logLevel.rawValue) << 0
            if constrainedEnvironment { value |= 1 << (ESP_LOG_LEVEL_LEN + 0) }
            if requireFormatting { value |= 1 << (ESP_LOG_LEVEL_LEN + 1) }
            if disableColor { value |= 1 << (ESP_LOG_LEVEL_LEN + 2) }
            if disableTimestamp { value |= 1 << (ESP_LOG_LEVEL_LEN + 3) }
            if binaryMode { value |= 1 << (ESP_LOG_LEVEL_LEN + 4) }
            value |= UInt32(reserved) << (ESP_LOG_LEVEL_LEN + 5)
            return value
        }

        /// The ESP-IDF log configuration structure.
        var espLogConfig: esp_log_config_t {
            var config = esp_log_config_t()
            config.opts.log_level = logLevel.espLevel
            config.opts.constrained_env = constrainedEnvironment ? 1 : 0
            config.opts.require_formatting = requireFormatting ? 1 : 0
            config.opts.dis_color = disableColor ? 1 : 0
            config.opts.dis_timestamp = disableTimestamp ? 1 : 0
            config.opts.binary_mode = binaryMode ? 1 : 0
            config.opts.reserved = UInt32(reserved)
            config.data = raw
            return config
        }
    }
}

extension Logger {
    /// Returns the substring after the final '/' or '\' in `path`.
    ///
    /// This function works on minimal (embedded) Swift runtimes without using `range(of:)`, `NSString`, `URL`, or `split`
    /// to avoid issues with `_swift_stdlib_getNormData` when trying to use `file.split(separator: "/")`.
    ///
    /// - SeeAlso: [Embedded Swift Strings Documentation](https://docs.swift.org/embedded/documentation/embedded/strings/)
    ///
    /// - Parameter path: The file path to extract the last component from.
    /// - Returns: The last component of the path.
    private func lastComponent(of path: String) -> String {
        // UTF‑8 view of the string – always available.
        let utf8View = path.utf8

        var lastSlashOffset: Int? = nil  // byte offset of the last separator

        // Scan the UTF‑8 bytes once.
        var offset = 0
        for byte in utf8View {
            if byte == UInt8(ascii: "/") || byte == UInt8(ascii: "\\") {
                lastSlashOffset = offset  // remember this position
            }
            offset += 1
        }

        // No separator → the whole string is the component.
        guard let slashOffset = lastSlashOffset else {
            return path
        }

        // The component starts one byte after the separator.
        let startOffset = slashOffset + 1

        // Convert the byte offset to a `String.Index`.
        let startIndex = String.Index(utf16Offset: startOffset, in: path)

        // Slice from `startIndex` to the end of the original string.
        return String(path[startIndex...])
    }
}
