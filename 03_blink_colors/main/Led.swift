/// A structure for controlling an addressable LED strip connected to an ESP32 GPIO pin.
///
/// This struct wraps ESP-IDF's LED strip functionality, providing a Swift interface to initialize
/// and control LED strips. It supports setting individual LED colors using RGB values.
///
/// ## Usage
/// Create an instance with the GPIO pin number and maximum LED count, then use `setLed(color:)`
/// to change the color of the first LED (index 0).
///
/// ```swift
/// let led = Led(gpioPin: 8, maxLeds: 1)
/// led.setLed(color: .red)
/// ```
///
/// - Note: This implementation assumes a single LED for simplicity. For strips with multiple LEDs,
/// modify `setLed` to accept an index parameter.
/// - Requires: ESP-IDF LED library to be linked.
struct Led {
    /// The GPIO (General Purpose Input/Output) pin number where the LED is connected.
    /// GPIO pins are like numbered ports on the microcontroller that let it connect to external devices.
    let gpioPin: Int
    let maxLeds: Int

    /// An internal handle to the LED, managed by ESP-IDF's C code.
    /// You don't need to interact with this directly—it's used behind the scenes.
    private let led_strip: led_strip_handle_t?

    /// Initializes a new LED controller.
    ///
    /// This method configures the ESP32's RMT peripheral and LED device for the specified GPIO pin.
    /// The LED is cleared to off state upon initialization.
    ///
    /// - Parameters:
    ///   - gpioPin: The GPIO pin number connected to the LED's data line.
    ///   - maxLeds: The maximum number of LEDs in the strip (default: 1).
    /// - Precondition: The GPIO pin must be a valid output pin and not used by other peripherals.
    /// - Postcondition: The LED is initialized and cleared.
    init(gpioPin: Int, maxLeds: Int = 1) {
        self.gpioPin = gpioPin
        self.maxLeds = maxLeds
        var led_strip_handle: led_strip_handle_t? = nil

        var strip_config = led_strip_config_t()  // zero‑initialize
        strip_config.strip_gpio_num = Int32(gpioPin)
        strip_config.max_leds = UInt32(maxLeds)

        var rmt_config = led_strip_rmt_config_t()
        rmt_config.resolution_hz = 10 * 1000 * 1000  // 10MHz
        rmt_config.flags.with_dma = 0  // 0 is false

        let error = led_strip_new_rmt_device(&strip_config, &rmt_config, &led_strip_handle)
        guard error == ESP_OK, let led_strip_handle else {
            fatalError("led_strip_new_rmt_device failed with error \(error)")
        }

        led_strip_clear(led_strip_handle)
        self.led_strip = led_strip_handle
    }

    /// Sets the color of the LED.
    ///
    /// This method updates the color of the LED at index 0 and refreshes the LED to display the change.
    /// Colors are specified as RGB values from 0-255.
    ///
    /// - Parameter color: The RGB color to set.
    /// - Note: Currently only supports a single LED. Extend for multiple LEDs by adding an index parameter.
    func setLed(color: Color) {
        // Set the LED pixel using RGB from 0 (0%) to 255 (100%) for each color
        led_strip_set_pixel(led_strip, 0, UInt32(color.r), UInt32(color.g), UInt32(color.b))
        // Refresh the LED to send data
        led_strip_refresh(led_strip)
    }
}

extension Led {
    /// Represents an RGB color for LED control.
    ///
    /// Colors are defined by red, green, and blue components, each ranging from 0 (off) to 255 (full brightness).
    /// Predefined static colors are available for common use.
    struct Color {
        let r: Int
        let g: Int
        let b: Int

        static let red = Color(r: 16, g: 0, b: 0)
        static let green = Color(r: 0, g: 16, b: 0)
        static let blue = Color(r: 0, g: 0, b: 16)
    }
}
