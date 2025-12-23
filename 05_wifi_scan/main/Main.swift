/// The entry point of the application, executed by ESP-IDF's runtime.
///
/// This function initializes the ESP32 chip, prints a greeting, scans for nearby Wi-Fi access points,
/// and prints their details (SSID, MAC address, channel, RSSI, authentication mode, and cipher).
/// The program demonstrates Wi-Fi scanning using the `WIFIScanner` struct.
///
/// - Note: The scan is performed once and the program exits. For continuous operation, modify the code.
/// - Important: Ensure the ESP32-C6 is properly set up with ESP-IDF and Swift toolchain before running.
@_cdecl("app_main")
func main() {
    let chipInformation = ChipInformation()
    print("Hello from Swift on \(chipInformation.name)!")

    let wifiScanner = WIFIScanner()
    let accessPoints = wifiScanner.scanAccessPoints(maxAccessPointsCount: 3)
    print("Got the following Access Points: \n")
    for accessPoint in accessPoints {
        print("SSID \t\t\(accessPoint.ssid)")
        print("Mac Address \t\(accessPoint.bssid)")
        print("Channel \t\(accessPoint.primaryChannel)")
        print("RSSI \t\t\(accessPoint.rssi)")
        print("AuthMode \t\(accessPoint.authMode.description)")
        print("Cipher \t\t\(accessPoint.pairwiseCipher.description)")
        print("")
    }
}
