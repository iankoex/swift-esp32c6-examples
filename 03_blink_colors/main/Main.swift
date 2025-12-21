/// The entry point of the application, executed by ESP-IDF's runtime.
///
/// This function initializes the ESP32 chip, prints a greeting, and enters an infinite loop
/// that cycles the LED through red, green, and blue colors every 500ms.
///
/// The program demonstrates basic LED control using the `Led` struct.
///
/// - Important: This loop runs indefinitely. To exit, reset or power cycle the device.
@_cdecl("app_main")
func main() {
    let chipInformation = ChipInformation()
    print("Hello from Swift on \(chipInformation.name)!")

    /// An LED controller connected to GPIO pin 8 on the ESP32 board.
    /// GPIO pins are connection points for attaching devices like LEDs or sensors.
    let led = Led(gpioPin: 8)

    while true {
        print("Turning LED to red")
        led.setLed(color: .red)
        vTaskDelay(500 / (1000 / UInt32(configTICK_RATE_HZ)))

        print("Turning LED to green")
        led.setLed(color: .green)
        vTaskDelay(500 / (1000 / UInt32(configTICK_RATE_HZ)))

        print("Turning LED to blue")
        led.setLed(color: .blue)
        vTaskDelay(500 / (1000 / UInt32(configTICK_RATE_HZ)))
    }
}
