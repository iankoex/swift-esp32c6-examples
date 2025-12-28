/// Swift Error Handling Utilities for ESP-IDF
///
/// This module provides basic error checking utilities for ESP-IDF applications written in Swift.
/// It includes a function to check for errors and abort on failure, along with an extension to make
/// `esp_err_t` conform to Swift's `Error` protocol for better integration with Swift error handling.
///
/// Key Features:
/// - **Error Checking**: `withErrorChecking` function that evaluates an expression, checks for ESP_OK,
///   and aborts with a descriptive message if an error occurs.
/// - **Error Conformance**: Extends `esp_err_t` to conform to `Error`, allowing use in `do-catch` blocks
///   and providing human-readable descriptions via `esp_err_to_name_r`.
///
///
/// Example Usage:
/// ```swift
/// // Basic error checking
/// withErrorChecking { someESPFunction() }
///
/// // Using esp_err_t as Error
/// do {
///     try throwingFunction()
/// } catch let error as esp_err_t {
///     print("ESP Error: \(error.description)")
/// }
/// ```
///
/// - SeeAlso: ESP-IDF Error Handling Guide (https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/error-handling.html)

// MARK: - Core Types and Helpers

/// Performs error checking on an ESP-IDF function call, aborting on failure.
///
/// This function evaluates the provided expression, checks if the returned `esp_err_t` is `ESP_OK`.
/// If not, it prints an error message including the file, function, and line, then aborts the program.
/// Useful for unrecoverable errors similar to ESP_ERROR_CHECK in ESP-IDF.
///
/// - Parameters:
///   - expression: A closure that returns an `esp_err_t` (e.g., an ESP-IDF API call).
///   - file: The source file where the call is made (default: #file).
///   - function: The function where the call is made (default: #function).
///   - line: The line number where the call is made (default: #line).
///
/// - Note: This is a fatal error handler; for recoverable errors, consider returning the error instead.
///
/// Example:
/// ```swift
/// withErrorChecking { spi_bus_initialize(host, &buscfg, dma_chan) }
/// ```
func withErrorChecking(
    _ expression: @escaping () -> esp_err_t, file: String = #file, function: String = #function, line: Int = #line
) {
    let error = expression()
    guard error != ESP_OK else { return }
    let message = error.description
    print("\(message)\n\(file):\(line) \(function)")
    esp_system_abort(message)
}

/// Extension to make esp_err_t conform to the Error protocol for Swift error handling.
/// Provides a human-readable description of ESP-IDF errors.
///
/// This allows `esp_err_t` values to be thrown and caught in Swift `do-catch` blocks,
/// and provides descriptive error messages using `esp_err_to_name_r`.
extension esp_err_t: @retroactive Error {
    /// A string description of the error, using esp_err_to_name_r if available.
    ///
    /// Attempts to convert the error code to a name string. If the conversion fails,
    /// falls back to a generic message with the numeric code.
    ///
    /// - Returns: A human-readable string describing the error.
    ///
    /// Example:
    /// ```swift
    /// let error: esp_err_t = ESP_ERR_NO_MEM
    /// print(error.description)  // "an error occured: ESP_ERR_NO_MEM"
    /// ```
    public var description: String {
        let bufferSize = 64
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        guard let result = esp_err_to_name_r(self, buffer, bufferSize) else {
            return "an error occured with error code: \(self)"
        }

        return "an error occured: " + String(cString: result)
    }
}
