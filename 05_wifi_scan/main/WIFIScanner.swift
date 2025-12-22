struct WIFIScanner {

    init() {
        initializeNVSFlash()
        initializeWIFI()
    }

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

    // maxAccessPointsCount is just a suggestion the actual number maybe lower
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
