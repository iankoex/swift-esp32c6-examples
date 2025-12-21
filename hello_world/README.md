# ESP32-C6 Hello World with Swift

This example demonstrates how to integrate with the ESP-IDF SDK via CMake and how to retrieve and display chip information from Swift. This example is specifically made for the RISC-V MCUs from ESP32 (the Xtensa MCUs are not currently supported by Swift).

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

- Chip information should be printed to the console/serial output.
- To exit the monitor, press `ctrl+]` or `ctrl+t` followed by `ctrl+x`.
