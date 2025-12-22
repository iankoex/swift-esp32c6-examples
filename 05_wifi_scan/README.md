# ESP32-C6 Temperature Reading Demo with Swift

This example demonstrates how to read temperature data from the ESP32-C6's built-in temperature sensor using Swift code that bridges to the ESP-IDF SDK's C APIs. This example is specifically made for the RISC-V MCUs from ESP32 (the Xtensa MCUs are not currently supported by Swift).

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

- The program will continuously read and print the temperature in Celsius every 500ms, with status messages printed to the console/serial output.
- To exit the monitor, press `ctrl+]` or `ctrl+t` followed by `ctrl+x`.

## Displaying Errors from C in Embedded Swift

In this demo, errors from ESP-IDF C APIs are handled by extending the `esp_err_t` type to conform to Swift's `Error` protocol. This allows C error codes to be thrown as Swift errors and caught in `do-catch` blocks. The extension provides a `description` property that converts the error code to a human-readable string using `esp_err_to_name`.

## Why Typed Throws

Embedded Swift restricts error handling to typed throws only, as untyped throws are not supported in constrained environments. Typed throws ensure type safety and allow specifying the exact error type (in this case, `esp_err_t`) that can be thrown. This is explained in more detail in the [Embedded Restrictions documentation](https://docs.swift.org/compiler/documentation/diagnostics/embedded-restrictions/).
