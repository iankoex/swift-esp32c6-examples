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

    func fastScan() {
        setUpEventHandlers()

        var wifi_config: wifi_config_t = .init(sta: .init())

        wifi_config.sta.ssid = "some ssid".toSSIDTuple()
        wifi_config.sta.password = "password".toPasswordTuple()
        wifi_config.sta.scan_method = WIFI_FAST_SCAN
        wifi_config.sta.sort_method = WIFI_CONNECT_AP_BY_SIGNAL
        wifi_config.sta.threshold.rssi = -127
        wifi_config.sta.threshold.authmode = WIFI_AUTH_OPEN
        wifi_config.sta.threshold.rssi_5g_adjustment = 0

        guard esp_wifi_set_mode(WIFI_MODE_STA) == ESP_OK else {
            fatalError("failed to set wifi mode to station")
        }

        guard esp_wifi_set_config(WIFI_IF_STA, &wifi_config) == ESP_OK else {
            fatalError("some thing ")
        }

        guard esp_wifi_start() == ESP_OK else {
            fatalError("failed to start wifi")
        }
    }

    private func setUpEventHandlers() {
        let wifiEventError = esp_event_handler_instance_register(
            WIFI_EVENT,
            ESP_EVENT_ANY_ID,
            eventHandler,
            nil,
            nil
        )
        guard wifiEventError == ESP_OK else {
            fatalError("wifiEventError")
        }
        let ipEventError = esp_event_handler_instance_register(
            IP_EVENT,
            Int32(IP_EVENT_STA_GOT_IP.rawValue),
            eventHandler,
            nil,
            nil
        )
        guard ipEventError == ESP_OK else {
            fatalError("ipEventError")
        }
    }
}

// handling c callbacks from swift
let eventHandler: esp_event_handler_t = { arg, event_base, event_id, event_data in
    print("calling, event_id: \(event_id)")

    if event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START.rawValue {
        print("connect")
        let error = esp_wifi_connect()
        print(error)
    } else if event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED.rawValue {
        print("disconnected")
        let error = esp_wifi_connect()
        print(error)
    } else if event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP.rawValue {
        print("got ip")
    }

    // Your event handling code here
    // self?.handleEvent(event_base: event_base, event_id: event_id, event_data: event_data)
}

extension String {
    /// Returns a 33-element tuple suitable for direct assignment to C ssid[33]
    func toSSIDTuple() -> (
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,

    ) {
        let bytes = self.utf8.prefix(32)
        var array = Array(bytes)
        array.append(0)  // null terminator
        while array.count < 33 { array.append(0) }

        return (
            array[0], array[1], array[2], array[3], array[4], array[5], array[6], array[7],
            array[8], array[9], array[10], array[11], array[12], array[13], array[14], array[15],
            array[16], array[17], array[18], array[19], array[20], array[21], array[22], array[23],
            array[24], array[25], array[26], array[27], array[28], array[29], array[30], array[31]
        )
    }

    func toPasswordTuple() -> (
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
    ) {
        // Take up to 63 bytes (leaving room for null terminator)
        let utf8Bytes = Array(self.utf8.prefix(63))

        var array = utf8Bytes
        array.append(0)  // null terminator (highly recommended)

        // Pad with zeros to exactly 64 bytes
        while array.count < 64 {
            array.append(0)
        }

        // Unpack into the 64-element tuple
        return (
            array[0], array[1], array[2], array[3], array[4], array[5], array[6], array[7],
            array[8], array[9], array[10], array[11], array[12], array[13], array[14], array[15],
            array[16], array[17], array[18], array[19], array[20], array[21], array[22], array[23],
            array[24], array[25], array[26], array[27], array[28], array[29], array[30], array[31],
            array[32], array[33], array[34], array[35], array[36], array[37], array[38], array[39],
            array[40], array[41], array[42], array[43], array[44], array[45], array[46], array[47],
            array[48], array[49], array[50], array[51], array[52], array[53], array[54], array[55],
            array[56], array[57], array[58], array[59], array[60], array[61], array[62], array[63]
        )
    }
}
