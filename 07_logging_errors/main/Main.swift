/// The entry point of the application, executed by ESP-IDF's runtime.
///
/// This function initializes the ESP32 chip, prints a greeting, and demonstrates the `Logger` class
/// by logging messages at different levels (error, warning, info, debug, verbose, none).
/// It showcases how the logger integrates with ESP-IDF's logging system and respects log levels.
///
/// - Note: By default, ESP-IDF's menuconfig sets the log level to info, so debug and verbose messages may not appear.
/// - Important: Ensure the ESP32-C6 is properly set up with ESP-IDF and Swift toolchain before running.
@_cdecl("app_main")
func main() {
    let chipInformation = ChipInformation()
    print("Hello from Swift on \(chipInformation.name)!")

    /// Create a logger instance with the label "example".
    let logger = Logger(label: "example")

    /*
    By default, ESP-IDF's menuconfig sets the log level to info.
    Therefore, any level above info (debug & verbose) will not log.
    The .none level will log as .info due to the hardcoded override in the logger.
    */
    logger.error("error")
    logger.warning("warning")
    logger.info("info")
    logger.debug("debug")
    logger.verbose("verbose")
    logger.log(level: .none, message: "none")

    let items = [1, 2, 3]
    logger.info("items: \(items)")

}
