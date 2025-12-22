/// A wrapper struct for ESP-IDF temperature sensor functionality.
/// This struct manages the initialization and reading of temperature data from the ESP32's built-in temperature sensor.
struct TemperatureReader {
    /// The handle to the temperature sensor instance.
    private let temp_sensor: temperature_sensor_handle_t

    /// Initializes the temperature sensor with default configuration.
    /// Configures the sensor with a temperature range of 10°C to 50°C and default clock source.
    /// Installs and enables the sensor, fatal error if installation or enabling fails.
    init() {
        var temp_sensor: temperature_sensor_handle_t? = nil
        var temp_sensor_config: temperature_sensor_config_t = temperature_sensor_config_t()
        temp_sensor_config.range_min = 10
        temp_sensor_config.range_max = 50
        temp_sensor_config.clk_src = TEMPERATURE_SENSOR_CLK_SRC_DEFAULT

        guard temperature_sensor_install(&temp_sensor_config, &temp_sensor) == ESP_OK else {
            fatalError("failed to install temperature sensor")
        }

        guard temperature_sensor_enable(temp_sensor) == ESP_OK else {
            fatalError("failed to enable temperature sensor")
        }

        guard let temp_sensor else {
            fatalError("temperature sensor should not be nil")
        }
        self.temp_sensor = temp_sensor
    }

    /// Reads the current temperature in Celsius from the sensor.
    /// - Returns: The temperature value in Celsius as a Float.
    /// - Throws: An esp_err_t error if the temperature reading fails.
    func getTemperatureInCelsius() throws(esp_err_t) -> Float {
        var teperature_sensor_value: Float = 0
        let error = temperature_sensor_get_celsius(temp_sensor, &teperature_sensor_value)
        guard error == ESP_OK else {
            throw error
        }
        return teperature_sensor_value
    }
}

/// Extension to make esp_err_t conform to the Error protocol for Swift error handling.
/// Provides a human-readable description of ESP-IDF errors.
extension esp_err_t: @retroactive Error {
    /// A string description of the error, using esp_err_to_name if available.
    public var description: String {
        guard let error_char = esp_err_to_name(self) else {
            return "an error occured with error code: \(self)"
        }
        return "an error occured: " + String(cString: error_char)
    }
}
