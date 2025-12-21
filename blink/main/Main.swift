/// The entry point of the app, called by ESP-IDF's C runtime.
///
///
/// ## What This Function Does
/// 1. Creates an LED controller connected to GPIO pin 8.
/// 2. Runs an infinite loop that blinks the LED on and off every second, printing status messages.
///
///
/// ## Example Output
/// ```
/// Hello from Swift on ESP32-C6!
/// Turning LED ON
/// Turning LED OFF
/// Turning LED ON
/// ... (continues forever)
/// ```
///
@_cdecl("app_main")
func main() {
    let chipInformation = ChipInformation()
    print("Hello from Swift on \(chipInformation.name)!")

    /// An LED controller connected to GPIO pin 8 on the ESP32 board.
    /// GPIO pins are connection points for attaching devices like LEDs or sensors.
    let led = Led(gpioPin: 8)

    /// A boolean flag that tracks whether the LED should be on (true) or off (false).
    /// It starts as true, so the LED turns on first.
    var ledValue: Bool = true

    /// An infinite loop that blinks the LED every second.
    /// This is common in embedded programming where the program needs to run continuously.
    while true {
        print("Turning LED \(ledValue ? "ON" : "OFF")")
        led.setLed(value: ledValue)

        /// Toggle the LED state: if it was on, make it off, and vice versa.
        ledValue.toggle()

        /// Pause for 1 second before the next blink.
        /// This uses ESP-IDF's timing function
        vTaskDelay(1000 / (1000 / UInt32(configTICK_RATE_HZ)))
    }
}
