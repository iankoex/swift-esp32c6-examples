/// A Swift wrapper for retrieving chip information from ESP-IDF's C APIs.
///
/// This struct acts as a bridge between Swift and the C code in ESP-IDF, allowing you to easily access details about your ESP32 chip without directly dealing with C structs or functions. It's perfect for newcomers to Swift embedded programming, as it hides the complexity of calling C functions like `esp_chip_info()`.
///
/// To use it, simply create an instance and read its properties. For example:
///
///     let info = ChipInformation()
///     print("Chip name: \(info.name)")
///
/// - Note: This requires the ESP-IDF SDK to be set up, as it calls C functions under the hood.
struct ChipInformation: Sendable {
    /// The number of CPU cores in the chip.
    ///
    /// This tells you how many "brains" the chip has for processing tasks. Retrieved from ESP-IDF's C API via bridging.
    let cores: UInt8

    /// The specific model of the ESP32 chip, like ESP32-C6 or ESP32-S3.
    ///
    /// This matches the C enum from ESP-IDF. It's optional in case the model isn't recognized. For example, if your chip is an ESP32-C6, this will be `.esp32C6`.
    let model: ChipModel?

    /// The capabilities of the chip, such as Wi-Fi or Bluetooth.
    ///
    /// This is a collection of features (like a checklist) from the C API. Use it to check what your chip can do.
    let features: ChipFeature

    /// The silicon revision of the chip, like a version number.
    ///
    /// This indicates the hardware version. For example, 100 means v1.00. Comes from C API bridging.
    let revision: UInt16

    /// A human-readable name for the chip model.
    ///
    /// This is a friendly string, like "ESP32-C6", derived from the model. Falls back to a config value if model is unknown.
    var name: String {
        model?.description ?? CONFIG_IDF_TARGET
    }

    /// Creates a new instance by fetching chip info from the C API.
    ///
    /// This initializer calls the ESP-IDF C function `esp_chip_info()` to get details, then safely maps them to Swift types.
    init() {
        var info = esp_chip_info_t()  // allocate on the stack
        esp_chip_info(&info)
        self.cores = info.cores
        self.model = ChipModel(rawValue: info.model.rawValue)
        self.features = ChipFeature(rawValue: info.features)
        self.revision = info.revision
    }
}
extension ChipInformation {
    /// An enum for ESP32 chip models, bridging directly from ESP-IDF's C enum.
    ///
    /// This enum lets Swift code understand and use the chip model values from the C API `esp_chip_info_t`. The raw values are identical to the C `esp_chip_model_t` enum, ensuring safe mapping without conversion.
    enum ChipModel: UInt32 {
        case esp32 = 1  // CHIP_ESP32
        case esp32S2 = 2  // CHIP_ESP32S2
        case esp32C3 = 5  // CHIP_ESP32C3
        case esp32C2 = 12  // CHIP_ESP32C2
        case esp32C6 = 13  // CHIP_ESP32C6
        case esp32H2 = 16  // CHIP_ESP32H2
        case esp32P4 = 18  // CHIP_ESP32P4
        case esp32C61 = 20  // CHIP_ESP32C61
        case esp32S3 = 9  // CHIP_ESP32S3
        case esp32C5 = 23  // CHIP_ESP32C5
        case esp32H21 = 25  // CHIP_ESP32H21
        case esp32H4 = 28  // CHIP_ESP32H4
        case posixLinux = 999  // CHIP_POSIX_LINUX (simulator)

        /// Human‑readable name
        var description: String {
            switch self {
                case .esp32: return "ESP32"
                case .esp32S2: return "ESP32‑S2"
                case .esp32S3: return "ESP32‑S3"
                case .esp32C3: return "ESP32‑C3"
                case .esp32C2: return "ESP32‑C2"
                case .esp32C6: return "ESP32‑C6"
                case .esp32H2: return "ESP32‑H2"
                case .esp32P4: return "ESP32‑P4"
                case .esp32C61: return "ESP32‑C61"
                case .esp32C5: return "ESP32‑C5"
                case .esp32H21: return "ESP32‑H21"
                case .esp32H4: return "ESP32‑H4"
                case .posixLinux: return "POSIX/Linux simulator"
            }
        }
    }
}

extension ChipInformation {
    /// A set of chip features, like checkboxes for capabilities, bridging from ESP-IDF's C macros.
    ///
    /// This OptionSet lets you check or combine features (e.g., if the chip supports Wi-Fi). Each flag directly matches a C BIT macro from `esp_system.h`.
    struct ChipFeature: OptionSet {
        let rawValue: UInt32

        // MARK: - Individual flags (match the C `CHIP_FEATURE_…` macros)
        static let embeddedFlash = ChipFeature(rawValue: 1 << 0)  // BIT(0)
        static let wifiBGN = ChipFeature(rawValue: 1 << 1)  // BIT(1)
        static let ble = ChipFeature(rawValue: 1 << 4)  // BIT(4)
        static let bluetooth = ChipFeature(rawValue: 1 << 5)  // BIT(5)
        static let ieee802154 = ChipFeature(rawValue: 1 << 6)  // BIT(6)
        static let embeddedPSRAM = ChipFeature(rawValue: 1 << 7)  // BIT(7)

        // MARK: - Convenience collection
        static let all: [ChipFeature] = [
            .embeddedFlash,
            .wifiBGN,
            .ble,
            .bluetooth,
            .ieee802154,
            .embeddedPSRAM,
        ]

        /// A user-friendly, comma-separated list of the enabled features.
        var description: String {
            var parts: [String] = []
            if contains(.embeddedFlash) { parts.append("Embedded Flash") }
            if contains(.wifiBGN) { parts.append("Wi‑Fi BGN") }
            if contains(.ble) { parts.append("BLE") }
            if contains(.bluetooth) { parts.append("Bluetooth Classic") }
            if contains(.ieee802154) { parts.append("IEEE 802.15.4 (Zigbee/Thread)") }
            if contains(.embeddedPSRAM) { parts.append("Embedded PSRAM") }
            return parts.joined(separator: ", ")
        }
    }
}
