/// A utility struct for scanning nearby Wi-Fi access points on ESP32 devices using ESP-IDF.
///
/// This struct provides an interface to initialize the Wi-Fi stack and perform scans for available networks.
/// It wraps ESP-IDF's Wi-Fi scanning APIs, handling initialization of NVS flash and Wi-Fi components.
///
/// - Note: Scanning is a blocking operation and may take several seconds. Ensure the device is in station mode.
/// - Important: This struct is not thread-safe; avoid concurrent scans.
struct WIFIScanner {

    /// Initializes the Wi-Fi scanner by setting up the NVS flash and Wi-Fi stack.
    ///
    /// This initializer configures the ESP-IDF NVS flash storage and prepares the Wi-Fi interface for scanning.
    /// It must be called before performing any scans. If initialization fails, the program will terminate.
    ///
    /// - Warning: Call this initializer only once per application run, as re-initialization may cause issues.
    init() {
        initializeNVSFlash()
        initializeWIFI()
    }

    /// Initializes the NVS (Non-Volatile Storage) flash for Wi-Fi configuration persistence.
    ///
    /// This method sets up or erases NVS flash if needed, ensuring Wi-Fi settings can be stored.
    private func initializeNVSFlash() {
        var error: esp_err_t = nvs_flash_init()
        if error == ESP_ERR_NVS_NO_FREE_PAGES || error == ESP_ERR_NVS_NEW_VERSION_FOUND {
            nvs_flash_erase()
            error = nvs_flash_init()
        }
        guard error == ESP_OK else {
            fatalError("failed to initialize the NVS flash")
        }
    }

    /// Initializes the Wi-Fi stack and event loop for ESP-IDF.
    ///
    /// This method sets up the default Wi-Fi station interface and event handling loop.
    private func initializeWIFI() {
        guard esp_netif_init() == ESP_OK else {
            fatalError("failed to init")
        }
        // event loop required by esp_netif_create_default_wifi_sta
        guard esp_event_loop_create_default() == ESP_OK else {
            fatalError("failed to create default event loop")
        }

        guard esp_netif_create_default_wifi_sta() != nil else {
            fatalError("failed to create default wifi sta")
        }

        var wifi_config: wifi_init_config_t = shim_wifi_init_config()
        guard esp_wifi_init(&wifi_config) == ESP_OK else {
            fatalError("failed to init wifi config")
        }
    }

    /// Scans for nearby Wi-Fi access points and returns their details.
    ///
    /// This method performs a Wi-Fi scan in station mode, retrieving information about available networks.
    /// The scan is blocking and may take a few seconds to complete. Progress is printed to the console.
    ///
    /// - Parameter maxAccessPointsCount: The maximum number of access points to retrieve (default: 3).
    ///   This is a suggestion; the actual number returned may be lower due to scan results or hardware limits.
    /// - Returns: An array of `WIFIAccessPointRecord` containing details of the scanned access points.
    ///
    /// - Note: The device must be initialized via this struct's initializer before calling this method.
    /// - Warning: If the scan fails, the program will terminate with a fatal error.
    ///
    /// ## Example
    /// ```swift
    /// let scanner = WIFIScanner()
    /// let accessPoints = scanner.scanAccessPoints(maxAccessPointsCount: 5)
    /// for ap in accessPoints {
    ///     print("SSID: \(ap.ssid), RSSI: \(ap.rssi)")
    /// }
    /// ```
    func scanAccessPoints(maxAccessPointsCount: Int = 3) -> [WIFIAccessPointRecord] {
        var number_of_access_points: UInt16 = UInt16(maxAccessPointsCount)
        let ap_info_array: UnsafeMutablePointer<wifi_ap_record_t> = .allocate(
            capacity: maxAccessPointsCount
        )

        guard esp_wifi_set_mode(WIFI_MODE_STA) == ESP_OK else {
            fatalError("failed to set wifi mode to station")
        }

        guard esp_wifi_start() == ESP_OK else {
            fatalError("failed to start wifi")
        }

        // ESP32C6 does not use USE_CHANNEL_BITMAP
        // esp_wifi_scan_start is a blocking function when called with true
        print("Scanning Nearby Access Points ...")
        guard esp_wifi_scan_start(nil, true) == ESP_OK else {
            fatalError("failed to start scanning")
        }
        print("Scan Complete")
        var scanned_aps_count: UInt16 = 0
        guard esp_wifi_scan_get_ap_num(&scanned_aps_count) == ESP_OK else {
            fatalError("failed to get the count of scanned access points")
        }
        print("Scanned a total number of \(scanned_aps_count) Access Points")

        guard esp_wifi_scan_get_ap_records(&number_of_access_points, ap_info_array) == ESP_OK else {
            fatalError("failed to get ap records")
        }
        print("Got a total of \(number_of_access_points) Access Points")

        let accessPointsRecords = (0..<Int(number_of_access_points)).compactMap {
            WIFIAccessPointRecord(ap_info_array[$0])
        }
        return accessPointsRecords
    }
}
