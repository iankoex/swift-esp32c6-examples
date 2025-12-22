/// The entry point of the application, executed by ESP-IDF's runtime.
///
/// This function initializes the ESP32 chip, prints a greeting, initializes the temperature sensor,
/// and enters an infinite loop that reads and prints the temperature every 500ms.
///
/// The program demonstrates temperature sensor reading using the `TemperatureReader` struct.
///
/// - Important: This loop runs indefinitely. To exit, reset or power cycle the device.
//
//

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

    while true {

        vTaskDelay(500 / (1000 / UInt32(configTICK_RATE_HZ)))
    }
}
