# ESP32-C6 Wi-Fi Scanning Demo with Swift

This example demonstrates how to scan for nearby Wi-Fi access points on the ESP32-C6 using Swift code that bridges to the ESP-IDF SDK's C APIs. This example is specifically made for the RISC-V MCUs from ESP32 (the Xtensa MCUs are not currently supported by Swift).

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

- The program will scan for nearby Wi-Fi access points and print their details (SSID, BSSID, channel, RSSI, auth mode, cipher), then exit.
- To exit the monitor, press `ctrl+]` or `ctrl+t` followed by `ctrl+x`.

## Converting C Arrays (uint8_t) to Swift Strings

When interfacing with C APIs in ESP-IDF, data like SSIDs or BSSIDs are often represented as fixed-size arrays of `uint8_t` (e.g., `char ssid[32]`). In Swift, these are imported as tuples (e.g., `(UInt8, UInt8, ..., UInt8)` for a fixed size). To convert them to usable Swift strings or hex representations:

### To a Valid String (e.g., SSID)
Use `withUnsafeBytes` to bind the tuple to an array of `UInt8`, then create a `String` from the C string:

```swift
let ssidArray: [UInt8] = withUnsafeBytes(of: wifi_ap_record.ssid) { buffer in
    Array(buffer.bindMemory(to: UInt8.self))
}
let ssid = String(cString: ssidArray)
```

This assumes the array is null-terminated, as is common for C strings.

### To Hex String (e.g., BSSID)
Map each byte to its hexadecimal string representation and join:

```swift
let bssidArray: [UInt8] = withUnsafeBytes(of: wifi_ap_record.bssid) { buffer in
    Array(buffer.bindMemory(to: UInt8.self))
}
let bssidHex = bssidArray.map { String($0, radix: 16, uppercase: true) }.joined()
```

This produces a string like "AABBCCDDEEFF" for MAC addresses.

## Workaround for Calling Complex C Macros in Swift

ESP-IDF uses complex macros (e.g., `WIFI_INIT_CONFIG_DEFAULT()`) that expand to struct initializers or expressions, which cannot be directly used in Swift due to limitations of Embedded Swift.
As a workaround, define a C shim function that assigns the macro to a variable and returns it.

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
