/// A simple controller for an LED (light-emitting diode) strip connected to an ESP32 microcontroller.
///
/// This struct acts as a bridge between Swift code and the low-level C functions provided by ESP-IDF (Espressif's framework for ESP32 devices).
/// It allows you to control a single LED in an addressable RGB strip without needing to know the details of C programming.
/// An "LED strip" is a chain of small lights that can be individually controlled to show different colors or brightness levels.
///
/// ## Overview
/// - The LED is connected to a specific "GPIO pin" (a numbered connection point on the microcontroller for attaching devices like sensors or lights).
/// - Internally, it uses ESP-IDF's C-based LED strip functions to communicate with the hardware.
/// - This is a great example of how Swift can work alongside C code in embedded systems, making hardware control easier for Swift developers.
///
/// ## Usage Example
/// ```swift
/// // Create an LED connected to GPIO pin 8
/// let myLed = Led(gpioPin: 8)
///
/// // Turn the LED on (it will glow with a soft white color)
/// myLed.setLed(value: true)
///
/// // Turn the LED off
/// myLed.setLed(value: false)
/// ```
struct Led {
    /// The GPIO (General Purpose Input/Output) pin number where the LED strip is connected.
    /// GPIO pins are like numbered ports on the microcontroller that let it connect to external devices.
    let gpioPin: Int32

    /// An internal handle to the LED strip, managed by ESP-IDF's C code.
    /// You don't need to interact with this directly—it's used behind the scenes.
    private var led_strip: led_strip_handle_t? = nil

    /// Creates a new LED controller connected to the specified GPIO pin.
    ///
    /// This initializer sets up the hardware connection and prepares the LED for use.
    /// If the setup fails (for example, if the pin is already in use), the program will stop with an error message.
    ///
    /// - Parameter gpioPin: The GPIO pin number (e.g., 8) where your LED strip's data wire is connected.
    ///   Check your ESP32 board's pinout diagram to find available GPIO pins.
    init(gpioPin: Int32) {
        self.gpioPin = gpioPin
        configureLed()
    }

    /// Configures the LED strip hardware using ESP-IDF's C functions.
    ///
    /// This private method handles the low-level setup required to communicate with the LED strip.
    /// It configures the GPIO pin, sets up timing for data transmission, and clears the LED to start in an off state.
    /// You don't need to call this directly—it's automatically run when creating a new `Led` instance.
    ///
    /// - Note: This method bridges to C code via Swift's C interoperability, which allows Swift to use existing C libraries like ESP-IDF.
    private mutating func configureLed() {
        var strip_config = led_strip_config_t()  // zero‑initialize
        strip_config.strip_gpio_num = gpioPin
        strip_config.max_leds = 1

        var rmt_config = led_strip_rmt_config_t()
        rmt_config.resolution_hz = 10 * 1000 * 1000  // 10MHz
        rmt_config.flags.with_dma = 0  // 0 is false

        let error = led_strip_new_rmt_device(&strip_config, &rmt_config, &led_strip)
        guard error == ESP_OK else {
            fatalError("led_strip_new_rmt_device failed with error \(error)")
        }
        led_strip_clear(led_strip)
    }

    /// Turns the LED on or off.
    ///
    /// - Parameter value: `true` to turn the LED on (it will display a soft white glow), `false` to turn it off (completely dark).
    ///
    /// When turned on, the LED shows a balanced mix of red, green, and blue light (RGB values of 16 each, which is about 6% brightness per color).
    /// This creates a gentle white light rather than full brightness, which is easier on the eyes and uses less power.
    ///
    /// ## How It Works
    /// - **On**: Sends color data to the LED and refreshes the strip to display the light.
    /// - **Off**: Clears all pixels, turning everything off.
    /// - The actual work is done by calling ESP-IDF's C functions, which handle the precise timing needed to control the LED hardware.
    ///
    /// - Note: This demonstrates Swift calling into C code seamlessly, allowing modern Swift syntax to control embedded hardware.
    func setLed(value: Bool) {
        if value {
            /* Set the LED pixel using RGB from 0 (0%) to 255 (100%) for each color */
            led_strip_set_pixel(led_strip, 0, 16, 16, 16)
            /* Refresh the strip to send data */
            led_strip_refresh(led_strip)
        } else {
            /* Set all LED off to clear all pixels */
            led_strip_clear(led_strip)
        }
    }
}
