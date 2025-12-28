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

## Workaround for ESP-IDF Logging Integration

ESP-IDF's logging functions require specific configuration structures. The code uses shim functions (defined in C) to interface with ESP-IDF's `esp_log` API, allowing Swift code to set log levels and configurations per message. This ensures compatibility with Embedded Swift limitations while providing full logging functionality.
