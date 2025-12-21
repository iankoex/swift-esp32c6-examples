/// The entry point of the app, called by ESP-IDF's C runtime.
///
/// This function demonstrates retrieving and printing chip information using Swift's bridging to C APIs.
/// It's marked with `@_cdecl` to expose it to the C side as "app_main",
/// which ESP-IDF calls when the program starts.
/// Perfect for newcomers learning how Swift integrates with C in embedded systems.
///
/// Example output:
/// Hello from Swift on ESP32-C6!
/// This is a ESP32-C6 chip with 1 CPU core(s)
/// It has Embedded Flash, Wi-Fi BGN features
/// Silicon Revision: v1.0
///
@_cdecl("app_main")
func main() {
    let chipInformation = ChipInformation()
    print("Hello from Swift on \(chipInformation.name)!")

    print("This is a \(chipInformation.name) chip with \(chipInformation.cores) CPU core(s)")
    print("It has \(chipInformation.features.description)")
    print("Silicon Revision: v\(chipInformation.revision / 100).\(chipInformation.revision % 100)")

    return
}
