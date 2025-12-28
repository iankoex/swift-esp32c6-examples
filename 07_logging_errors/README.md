# ESP32-C6 Logging Errors Demo with Swift

This example demonstrates how to use a custom `Logger` class in Swift to log messages at different severity levels (error, warning, info, debug, verbose, none) on the ESP32-C6. The logger integrates with ESP-IDF's logging system and supports customizable configuration options. This example is specifically made for the RISC-V MCUs from ESP32 (the Xtensa MCUs are not currently supported by Swift).

## Requirements

- Set up the [ESP-IDF](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/) development environment. Follow the steps in the [ESP32-C6 "Get Started" guide](https://docs.espressif.com/projects/esp-idf/en/v5.2/esp32c6/get-started/index.html).
    - Make sure you specifically set up development for the RISC-V ESP32-C6, and not the Xtensa based products.
- Before trying to use Swift with the ESP-IDF SDK, make sure your environment works and can build the provided C/C++ sample projects, in particular:
    - Try building and running a sample project from ESP-IDF written in C.

## Building

- Make sure you have a recent nightly Swift toolchain that has Embedded Swift support.
- If needed, run export.sh to get access to the idf.py script from ESP-IDF.
- Specify the target board type by using `idf.py set-target`.

```console
$ cd hello_world
$ . <path-to-esp-idf>/export.sh
$ idf.py set-target esp32c6
$ idf.py build
```

## Running

- Connect the ESP32-C6 board (or any other ESP32-C6 board) over a USB cable to your Mac.
- Use `idf.py` to upload the firmware and to run it:

```console
$ idf.py flash monitor
```

- The program will initialize the logger and demonstrate logging at different levels: error, warning, info, debug, verbose, and none.
- Note: By default, ESP-IDF's configuration sets the global log level to `info`, so `debug` and `verbose` messages may not appear unless the configuration is adjusted.
- To exit the monitor, press `ctrl+]` or `ctrl+t` followed by `ctrl+x`.

## Logger Class Usage

The `Logger` class provides a Swift interface to ESP-IDF's logging system with the following features:

- **Log Levels**: Supports standard ESP-IDF levels (none, error, warning, info, debug, verbose)
- **Configuration**: Customizable options for formatting, colors, timestamps, and binary mode
- **File Context**: Automatically includes file name, function, and line number in log messages

### Basic Usage

```swift
let logger = Logger(label: "MyApp")
logger.error("An error occurred")
logger.warning("This is a warning")
logger.info("Informational message")
logger.debug("Debug information")  // May not show if global level is below debug
```

### Custom Configuration

```swift
var config = Logger.Configuration()
config.logLevel = .debug
config.disableColor = true
let customLogger = Logger(label: "Custom", configuration: config)
customLogger.debug("This will show with custom settings")
```

## Embedded Swift Printing Limitations

Embedded Swift (as of the current snapshot) has limited support for certain standard library features, particularly around string interpolation and protocol conformances. This affects logging and debugging, especially when printing complex types like arrays.

### Why Can't You Just Log Types?

Most primitives extended by `ExpressibleByStringLiteral` and `ExpressibleByStringInterpolation` are unavailable in embedded Swift. Attempting to print arrays or use string interpolation with collections results in runtime errors:

```swift
let items = [1, 2, 3]
print(items) // Error: Conformance of 'Array<Element>' to 'CustomStringConvertible' is unavailable: unavailable in embedded Swift (SourceKit)
print("array contents: \(array)")  // will print but console will show: "array contents (cannot print value in embedded Swift)"
```

### Workarounds and Solutions

- **Manual Formatting**: Loop through elements or use custom formatting:
  ```swift
  print("array: [" + array.map { String($0) }.joined(separator: ", ") + "]")
  ```

### Logging with Types

Embedded Swift's limitations also impact logging with complex types. You can't log arrays or collections directly using string interpolation:

```swift
let items = [1, 2, 3]
logger.info("array contents: \(items)")  // Will print, but console shows: "I (280) example: items: (cannot print value in embedded Swift) • main() Main.swift:30"
```

Reimplementing `CustomStringConvertible` for all types is overkill, so the Logger requires you to provide a pre-formatted string instead.

Note: `ESP_LOG_LEVEL_LOCAL` can take variadic arguments, and `CVaListPointer` is available in embedded Swift, but `withVaList` doesn't work for some reason. We hope embedded Swift gains this support soon.

## Error Handling

This project demonstrates error handling in Swift for ESP32-C6, adapting ESP-IDF's robust error mechanisms to embedded Swift's constraints. Errors are primarily managed through `esp_err_t` return codes, with utilities in `Utilities.swift` providing safe checking and reporting.

### Key Features

- **Error Checking**: Use `withErrorChecking` for fatal errors, evaluating expressions and aborting on failure with descriptive messages.
- **Error Descriptions**: The `esp_err_t` extension conforms to `Error`, using `esp_err_to_name_r` for human-readable strings.
- **Logging Integration**: Combine with the `Logger` class to log errors at appropriate levels, avoiding interpolation issues.

### Basic Usage

```swift
// Check for errors and abort if failed
withErrorChecking { someESPFunction() }

// Log errors gracefully
if let error = someESPFunction(), error != ESP_OK {
    logger.error("Error: \(error.description)")
}
```

See `Utilities.swift` for API details and ESP-IDF's [Error Handling Guide](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/error-handling.html) for context.
