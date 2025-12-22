struct WIFIAccessPointRecord {
    let bssid: String
    let ssid: String
    let primaryChannel: Int
    let secondaryChannel: SecondaryChannel
    let rssi: Int
    let authMode: AuthMode
    let pairwiseCipher: CipherType
    let groupCipher: CipherType
    let antenna: Int
    let bandwith: Bandwidth
    // let phyFlags: PHYFlags

    init(_ wifi_ap_record: wifi_ap_record_t) {
        let bssidArray: [UInt8] = withUnsafeBytes(of: wifi_ap_record.bssid) { buffer in
            Array(buffer.bindMemory(to: UInt8.self))
        }
        let bssidHexStringArray = bssidArray.map({ String($0, radix: 16, uppercase: true) })
        self.bssid = bssidHexStringArray.joined()

        let ssidArray: [UInt8] = withUnsafeBytes(of: wifi_ap_record.ssid) { buffer in
            Array(buffer.bindMemory(to: UInt8.self))
        }
        self.ssid = String(cString: ssidArray)

        self.primaryChannel = Int(wifi_ap_record.primary)
        self.secondaryChannel = SecondaryChannel(rawValue: wifi_ap_record.second.rawValue) ?? .none
        self.rssi = Int(wifi_ap_record.rssi)
        self.authMode = AuthMode(rawValue: wifi_ap_record.authmode.rawValue) ?? .open
        self.pairwiseCipher = CipherType(rawValue: wifi_ap_record.pairwise_cipher.rawValue) ?? .unknown
        self.groupCipher = CipherType(rawValue: wifi_ap_record.pairwise_cipher.rawValue) ?? .unknown
        self.antenna = Int(wifi_ap_record.ant.rawValue)
        // self.phyFlags = PHYFlags(rawValue: wifi_ap_record.phy_lr)
        self.bandwith = Bandwidth(rawValue: wifi_ap_record.bandwidth.rawValue) ?? .ht20bw20  // missleading
    }
}

extension WIFIAccessPointRecord {
    enum SecondaryChannel: Int {
        typealias RawValue = Int

        init?(rawValue: UInt32) {
            self.init(rawValue: Int(rawValue))
        }

        /// 20 MHz channel width (no secondary channel)
        case none = 0

        /// 40 MHz channel width, secondary channel is **above** the primary channel
        case above

        /// 40 MHz channel width, secondary channel is **below** the primary channel
        case below
    }
}

extension WIFIAccessPointRecord {
    /// Wi-Fi authentication/security modes
    /// Matches ESP-IDF's `wifi_auth_mode_t` enum
    enum AuthMode: Int {
        typealias RawValue = Int

        init?(rawValue: UInt32) {
            self.init(rawValue: Int(rawValue))
        }

        /// Open network – no authentication or encryption required
        case open = 0

        /// WEP – Wired Equivalent Privacy (obsolete and insecure)
        case wep

        /// WPA Personal (TKIP) – Wi-Fi Protected Access with Pre-Shared Key
        case wpaPsk

        /// WPA2 Personal (CCMP/AES) – Most common modern personal mode
        case wpa2Psk

        /// Mixed WPA/WPA2 Personal – Supports both WPA and WPA2 clients
        case wpaWpa2Psk

        /// Enterprise mode (802.1X/EAP) – Usually maps to WPA2-Enterprise
        /// Explicit WPA2-Enterprise (same value as .enterprise)
        case enterprise

        /// WPA3 Personal (SAE) – Modern, stronger personal authentication
        case wpa3Psk

        /// WPA2/WPA3 Personal transition mode – Supports both WPA2 and WPA3
        case wpa2Wpa3Psk

        /// WAPI Personal – Chinese national standard (rare outside China)
        case wapiPsk

        /// Opportunistic Wireless Encryption – Open network with per-device encryption
        case owe

        /// WPA3 Enterprise with 192-bit security (Suite B)
        case wpa3Enterprise192Bit

        /// WPA3 Personal (extended PSK) – Deprecated – use `wpa3Psk` instead
        /// Will yield the same result as `wpa3Psk`
        case wpa3ExtendedPsk

        /// WPA3 Personal mixed mode (extended PSK) – Deprecated – use `wpa3Psk` instead
        /// Will yield the same result as `wpa3Psk`
        case wpa3ExtendedPskMixedMode

        /// Device Provisioning Protocol – For easy device onboarding
        case dpp

        /// WPA3 Enterprise Only – Strict WPA3-Enterprise (no WPA2 fallback)
        case wpa3Enterprise

        /// WPA2/WPA3 Enterprise transition mode – Supports both
        case wpa2Wpa3Enterprise

        /// WPA Enterprise – Older enterprise mode (rarely used today)
        case wpaEnterprise

        /// Sentinel value – maximum valid authentication mode
        /// (not a real mode, used internally)
        case max

        var description: String {
            switch self {
                case .open: return "Open (no security)"
                case .wep: return "WEP (obsolete)"
                case .wpaPsk: return "WPA Personal"
                case .wpa2Psk: return "WPA2 Personal"
                case .wpaWpa2Psk: return "WPA/WPA2 Personal (mixed)"
                case .enterprise: return "WPA2 Enterprise (802.1X)"
                case .wpa3Psk: return "WPA3 Personal (SAE)"
                case .wpa2Wpa3Psk: return "WPA2/WPA3 Personal (transition)"
                case .wapiPsk: return "WAPI Personal"
                case .owe: return "OWE (Opportunistic Wireless Encryption)"
                case .wpa3Enterprise192Bit: return "WPA3 Enterprise 192-bit (Suite B)"
                case .wpa3ExtendedPsk: return "WPA3 Extended PSK (deprecated)"
                case .wpa3ExtendedPskMixedMode: return "WPA3 Extended PSK Mixed (deprecated)"
                case .dpp: return "DPP (Device Provisioning Protocol)"
                case .wpa3Enterprise: return "WPA3 Enterprise Only"
                case .wpa2Wpa3Enterprise: return "WPA2/WPA3 Enterprise (transition)"
                case .wpaEnterprise: return "WPA Enterprise (old)"
                case .max: return "Max (internal sentinel)"
            }
        }
    }
}

extension WIFIAccessPointRecord {
    /// Wi-Fi cipher (encryption) type
    /// Matches ESP-IDF's `wifi_cipher_type_t` enum
    enum CipherType: Int {
        typealias RawValue = Int

        init?(rawValue: UInt32) {
            self.init(rawValue: Int(rawValue))
        }

        /// No encryption / cipher used (open network)
        case none = 0

        /// WEP 40-bit (obsolete, very insecure)
        case wep40

        /// WEP 104-bit (obsolete, very insecure)
        case wep104

        /// TKIP – Temporal Key Integrity Protocol (WPA, considered weak today)
        case tkip

        /// CCMP – AES-CCMP (most common modern cipher, used in WPA2)
        case ccmp

        /// Mixed TKIP + CCMP (transition mode, allows both old and new clients)
        case tkipCcmp

        /// AES-CMAC-128 (used in management frame protection / 802.11w)
        case aesCmac128

        /// SMS4 – Chinese national standard cipher (rare outside China)
        case sms4

        /// GCMP – Galois/Counter Mode Protocol (used in WPA3/Wi-Fi 6)
        case gcmp

        /// GCMP-256 – Stronger 256-bit version of GCMP
        case gcmp256

        /// AES-GMAC-128 (Galois Message Authentication Code, used in some WPA3 cases)
        case aesGmac128

        /// AES-GMAC-256 (stronger 256-bit version)
        case aesGmac256

        /// Cipher type is unknown / not recognized
        case unknown

        var description: String {
            switch self {
                case .none: return "None (open)"
                case .wep40: return "WEP 40-bit (obsolete)"
                case .wep104: return "WEP 104-bit (obsolete)"
                case .tkip: return "TKIP (WPA)"
                case .ccmp: return "CCMP/AES (WPA2)"
                case .tkipCcmp: return "TKIP+CCMP (mixed)"
                case .aesCmac128: return "AES-CMAC-128 (MFP)"
                case .sms4: return "SMS4 (Chinese standard)"
                case .gcmp: return "GCMP (WPA3/Wi-Fi 6)"
                case .gcmp256: return "GCMP-256"
                case .aesGmac128: return "AES-GMAC-128"
                case .aesGmac256: return "AES-GMAC-256"
                case .unknown: return "Unknown"
            }
        }
    }
}

extension WIFIAccessPointRecord {
    /// Wi-Fi channel bandwidth modes
    /// Matches ESP-IDF's `wifi_bandwidth_t` enum
    enum Bandwidth: Int {
        typealias RawValue = Int

        init?(rawValue: UInt32) {
            self.init(rawValue: Int(rawValue))
        }

        /// 20 MHz bandwidth (HT20) – most common and compatible
        case ht20bw20 = 1

        /// 40 MHz bandwidth (HT40) – wider channel, higher throughput
        case ht40bw40 = 2

        /// 80 MHz bandwidth – used in 5 GHz Wi-Fi (802.11ac and later)
        case bw80 = 3

        /// 160 MHz bandwidth – very wide channel, highest throughput (802.11ac/ax)
        case bw160 = 4

        /// 80+80 MHz – non-contiguous 80 MHz channels (rare, high-end 802.11ac/ax)
        case bw80Bw80 = 5

        var description: String {
            switch self {
                case .ht20bw20: return "20 MHz"
                case .ht40bw40: return "40 MHz"
                case .bw80: return "80 MHz"
                case .bw160: return "160 MHz"
                case .bw80Bw80: return "80+80 MHz (non-contiguous)"
            }
        }
    }
}

extension WIFIAccessPointRecord {
    struct PHYFlags: OptionSet {
        let rawValue: Int

        // Individual flags (bit positions match ESP-IDF)
        static let mode11b = PHYFlags(rawValue: 1 << 0)
        static let mode11g = PHYFlags(rawValue: 1 << 1)
        static let mode11n = PHYFlags(rawValue: 1 << 2)
        static let lowRate = PHYFlags(rawValue: 1 << 3)
        static let mode11a = PHYFlags(rawValue: 1 << 4)  // Sometimes mislabeled in docs
        static let mode11ac = PHYFlags(rawValue: 1 << 5)
        static let mode11ax = PHYFlags(rawValue: 1 << 6)
        static let wps = PHYFlags(rawValue: 1 << 7)
        static let ftmResponder = PHYFlags(rawValue: 1 << 8)
        static let ftmInitiator = PHYFlags(rawValue: 1 << 9)
    }
}
