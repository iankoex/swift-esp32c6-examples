# Embedded Swift Examples for ESP32-C6

This repository contains a collection of examples demonstrating how to use Embedded Swift on ESP32-C6 microcontrollers, including integration with ESP-IDF C APIs. These examples are specifically designed for the RISC-V MCUs from ESP32 (the Xtensa MCUs are not currently supported by Swift).

## Prerequisites

- **ESP-IDF Setup**: Set up the [ESP-IDF](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/) development environment. Follow the steps in the [ESP32-C6 "Get Started" guide](https://docs.espressif.com/projects/esp-idf/en/v5.2/esp32c6/get-started/index.html). Make sure you specifically set up development for the RISC-V ESP32-C6, and not the Xtensa based products. Before trying to use Swift with the ESP-IDF SDK, make sure your environment works and can build the provided C/C++ sample projects.
- **Swift Toolchain Installation**:
  - Install [Swiftly](https://www.swift.org/install/) - the Swift toolchain installer and manager.
  - Install the main snapshot (development snapshot): `swiftly install main-snapshot`
  - Select the toolchain: `swiftly use main-snapshot`
- **Verification**: Test with `swift --version` (should indicate a development/nightly build).

## General Building and Running Instructions

To build and run any example:

```console
$ cd <example_directory>
$ . <path-to-esp-idf>/export.sh
$ idf.py set-target esp32c6
$ idf.py build
$ idf.py flash monitor
```

- Connect the ESP32-C6 board over a USB cable.
- Use `idf.py flash monitor` to upload the firmware and run it.
- To exit the monitor, press `ctrl+]` or `ctrl+t` followed by `ctrl+x`.

## Examples

- **`01_hello_world/`**: Demonstrates how to integrate with the ESP-IDF SDK via CMake and retrieve/display chip information from Swift.
- **`02_blink/`**: Shows how to control an addressable RGB LED strip to create a blinking light effect using Swift code bridging to ESP-IDF C APIs.
- **`03_blink_colors/`**: Demonstrates controlling a multicolor LED to create a color cycling effect using Swift bridging to ESP-IDF C APIs.
- **`04_temperature/`**: Illustrates reading temperature data from the ESP32-C6's built-in temperature sensor using Swift bridging to ESP-IDF C APIs.
- **`05_wifi_scan/`**: Demonstrates scanning for nearby Wi-Fi access points on the ESP32-C6 using Swift bridging to ESP-IDF C APIs.

## Embedded Swift Usage Guide

### Typed Throws in Embedded Swift

Embedded Swift restricts error handling to typed throws only, as untyped throws are not supported in constrained environments. Typed throws ensure type safety and allow specifying the exact error type (in this case, `esp_err_t`) that can be thrown. This is explained in more detail in the [Embedded Restrictions documentation](https://docs.swift.org/compiler/documentation/diagnostics/embedded-restrictions/).

### Displaying Errors from C in Embedded Swift

In this example, errors from ESP-IDF C APIs are handled by extending the `esp_err_t` type to conform to Swift's `Error` protocol. This allows C error codes to be thrown as Swift errors and caught in `do-catch` blocks. The extension provides a `description` property that converts the error code to a human-readable string using `esp_err_to_name`.

### Using C Arrays in Swift

When interfacing with C APIs in ESP-IDF, data like SSIDs or BSSIDs are often represented as fixed-size arrays of `uint8_t` (e.g., `uint8_t ssid[32]`). In Swift, these are imported as tuples (e.g., `(UInt8, UInt8, ..., UInt8)` for a fixed size). To convert them to usable Swift strings or hex representations:

#### To a Valid String (e.g., SSID)
Use `withUnsafeBytes` to bind the tuple to an array of `UInt8`, then create a `String` from the C string:

```swift
let ssidArray: [UInt8] = withUnsafeBytes(of: wifi_ap_record.ssid) { buffer in
    Array(buffer.bindMemory(to: UInt8.self))
}
let ssid = String(cString: ssidArray)
```

This assumes the array is null-terminated, as is common for C strings.

#### To Hex String (e.g., BSSID)
Map each byte to its hexadecimal string representation and join:

```swift
let bssidArray: [UInt8] = withUnsafeBytes(of: wifi_ap_record.bssid) { buffer in
    Array(buffer.bindMemory(to: UInt8.self))
}
let bssidHex = bssidArray.map { String($0, radix: 16, uppercase: true) }.joined()
```

This produces a string like "AABBCCDDEEFF" for MAC addresses.

### Workarounds for Calling Complex C Macros in Swift

ESP-IDF uses complex macros (e.g., `WIFI_INIT_CONFIG_DEFAULT()`) that expand to struct initializers or expressions, which cannot be directly used in Swift due to limitations of Embedded Swift. As a workaround, define a C shim function that assigns the macro to a variable and returns it.

For example, in `BridgingHeader.h`:

```c
static inline wifi_init_config_t shim_wifi_init_config(void) {
  wifi_init_config_t config = WIFI_INIT_CONFIG_DEFAULT();
  return config;
}
```

Then, in Swift, call the shim:

```swift
var wifi_config: wifi_init_config_t = shim_wifi_init_config()
```

This approach ensures compatibility while avoiding direct macro usage. Use similar shims for other complex macros that aren't simple constants.

## License

- ESP-IDF and ESP related code is licensed under Apache License 2.0 with Runtime Library Exception.
- Original project code and examples are licensed under MIT License.

## Additional Resources

- [Build Embedded Swift Application for ESP32-C6](https://developer.espressif.com/blog/build-embedded-swift-application-for-esp32c6/) - Espressif blog post
- [Embedded Swift Documentation](https://www.swift.org/get-started/embedded/)
- [swift-embedded-examples Repository](https://github.com/swiftlang/swift-embedded-examples)
- [WWDC24 - Go small with Embedded Swift](https://developer.apple.com/videos/play/wwdc2024/10197/)

## Contributing

This is experimental software. For feedback or issues, please report at [GitHub Issues](https://github.com/iankoex/swift-esp32c6-examples/issues).
