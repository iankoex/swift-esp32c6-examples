/// The entry point of the application, executed by ESP-IDF's runtime.
///
/// This function initializes the ESP32 chip, prints a greeting, initializes the temperature sensor,
/// and enters an infinite loop that reads and prints the temperature every 500ms.
///
/// The program demonstrates temperature sensor reading using the `TemperatureReader` struct.
///
/// - Important: This loop runs indefinitely. To exit, reset or power cycle the device.
@_cdecl("app_main")
func main() {
    let chipInformation = ChipInformation()
    print("Hello from Swift on \(chipInformation.name)!")

    let temperatureReader = TemperatureReader()
    print("Temperature Reader Ready")

    while true {
        do {
            let temperatureValue = try temperatureReader.getTemperatureInCelsius()
            print("Temperature value: \(temperatureValue) ℃")
        } catch {
            print(error.description)
        }
        vTaskDelay(500 / (1000 / UInt32(configTICK_RATE_HZ)))
    }
}
