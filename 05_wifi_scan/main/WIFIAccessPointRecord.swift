/// Use this to access details about nearby Wi-Fi networks, such as their name, signal strength, and security.
struct WIFIAccessPointRecord {
    /// The AP's MAC address as a hex string (e.g., "AABBCCDDEEFF").
    let bssid: String

    /// The AP's network name (SSID) as a string.
    let ssid: String

    /// The primary Wi-Fi channel number (e.g., 1-14 for 2.4GHz).
    let primaryChannel: Int

    /// Secondary channel info for wider bandwidth (e.g., above or below primary).
    let secondaryChannel: SecondaryChannel

    /// Signal strength in dBm (negative values; stronger signal = less negative).
    let rssi: Int

    /// Authentication/security mode (e.g., WPA2, open network)..
    let authMode: AuthMode

    /// Encryption type for pairwise (unicast) traffic.
    let pairwiseCipher: CipherType

    /// Encryption type for group (multicast/broadcast) traffic.
    let groupCipher: CipherType

    /// Antenna used for receiving the beacon (0 or 1).
    let antenna: Int

    /// Bit flags for supported PHY modes and features (e.g., 11b, WPS).
    let phyFlags: PHYFlags

    /// Channel bandwidth (e.g., 20MHz, 80MHz).
    let bandwidth: Bandwidth

    /// Country-specific Wi-Fi regulations for this AP.
    let country: WIFICountry

    /// High-Efficiency (Wi-Fi 6) AP info, like BSS color.
    let heAPInfo: HEAPInfo

    /// Center channel frequency for 80/160MHz VHT bandwidth.
    let vhtChannelFreq1: Int

    /// Second segment center frequency for 80+80MHz bandwidth.
    let vhtChannelFreq2: Int

    /// Creates a Swift record from ESP-IDF's C struct.
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
        self.groupCipher = CipherType(rawValue: wifi_ap_record.group_cipher.rawValue) ?? .unknown
        self.antenna = Int(wifi_ap_record.ant.rawValue)

        var phyRaw: UInt32 = 0
        phyRaw |= (wifi_ap_record.phy_11b != 0 ? 1 : 0) << 0
        phyRaw |= (wifi_ap_record.phy_11g != 0 ? 1 : 0) << 1
        phyRaw |= (wifi_ap_record.phy_11n != 0 ? 1 : 0) << 2
        phyRaw |= (wifi_ap_record.phy_lr != 0 ? 1 : 0) << 3
        phyRaw |= (wifi_ap_record.phy_11a != 0 ? 1 : 0) << 4
        phyRaw |= (wifi_ap_record.phy_11ac != 0 ? 1 : 0) << 5
        phyRaw |= (wifi_ap_record.phy_11ax != 0 ? 1 : 0) << 6
        phyRaw |= (wifi_ap_record.wps != 0 ? 1 : 0) << 7
        phyRaw |= (wifi_ap_record.ftm_responder != 0 ? 1 : 0) << 8
        phyRaw |= (wifi_ap_record.ftm_initiator != 0 ? 1 : 0) << 9
        self.phyFlags = PHYFlags(rawValue: Int(phyRaw))

        self.country = WIFICountry(wifi_ap_record.country)
        self.heAPInfo = HEAPInfo(wifi_ap_record.he_ap)
        self.bandwidth = Bandwidth(rawValue: wifi_ap_record.bandwidth.rawValue) ?? .ht20bw20
        self.vhtChannelFreq1 = Int(wifi_ap_record.vht_ch_freq1)
        self.vhtChannelFreq2 = Int(wifi_ap_record.vht_ch_freq2)
    }
}

extension WIFIAccessPointRecord {
    /// Options for Wi-Fi secondary channels in wider bandwidth modes.
    enum SecondaryChannel: Int {
        /// The type of raw value this enum uses (matches C's enum).
        typealias RawValue = Int

        /// Initializes from a C UInt32 value.
        /// C enums are often UInt32, so we convert safely.
        ///
        /// - Parameter rawValue: The C enum value.
        init?(rawValue: UInt32) {
            self.init(rawValue: Int(rawValue))
        }

        /// 20 MHz channel width (no secondary channel).
        /// Most common for older devices or crowded areas.
        case none = 0

        /// 40 MHz channel width, secondary channel is **above** the primary channel.
        /// Like adding a lane to the right of your main road.
        case above

        /// 40 MHz channel width, secondary channel is **below** the primary channel.
        /// Adding a lane to the left.
        case below
    }
}

extension WIFIAccessPointRecord {
    /// Wi-Fi authentication/security modes for connecting to networks.
    enum AuthMode: Int {
        typealias RawValue = Int

        init?(rawValue: UInt32) {
            self.init(rawValue: Int(rawValue))
        }

        /// Open network – no authentication or encryption required
        case open = 0

        /// WEP – Wired Equivalent Privacy (obsolete and insecure)
        case wep = 1

        /// WPA Personal (TKIP) – Wi-Fi Protected Access with Pre-Shared Key
        case wpaPsk = 2

        /// WPA2 Personal (CCMP/AES) – Most common modern personal mode
        case wpa2Psk = 3

        /// Mixed WPA/WPA2 Personal – Supports both WPA and WPA2 clients
        case wpaWpa2Psk = 4

        /// Enterprise mode (802.1X/EAP) – Usually maps to WPA2-Enterprise
        /// Explicit WPA2-Enterprise (same value as .enterprise)
        case enterprise = 5

        /// WPA3 Personal (SAE) – Modern, stronger personal authentication
        case wpa3Psk = 6

        /// WPA2/WPA3 Personal transition mode – Supports both WPA2 and WPA3
        case wpa2Wpa3Psk = 7

        /// WAPI Personal – Chinese national standard (rare outside China)
        case wapiPsk = 8

        /// Opportunistic Wireless Encryption – Open network with per-device encryption
        case owe = 9

        /// WPA3 Enterprise with 192-bit security (Suite B)
        case wpa3Enterprise192Bit = 10

        /// WPA3 Personal (extended PSK) – Deprecated – use `wpa3Psk` instead
        /// Will yield the same result as `wpa3Psk`
        case wpa3ExtendedPsk = 11

        /// WPA3 Personal mixed mode (extended PSK) – Deprecated – use `wpa3Psk` instead
        /// Will yield the same result as `wpa3Psk`
        case wpa3ExtendedPskMixedMode = 12

        /// Device Provisioning Protocol – For easy device onboarding
        case dpp = 13

        /// WPA3 Enterprise Only – Strict WPA3-Enterprise (no WPA2 fallback)
        case wpa3Enterprise = 14

        /// WPA2/WPA3 Enterprise transition mode – Supports both
        case wpa2Wpa3Enterprise = 15

        /// WPA Enterprise – Older enterprise mode (rarely used today)
        case wpaEnterprise = 16

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
    /// Wi-Fi cipher (encryption) types for securing data.
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
    /// Wi-Fi channel bandwidth modes for data throughput.
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
    /// Bit flags for Wi-Fi PHY modes and features supported by the AP.
    struct PHYFlags: OptionSet {
        /// The raw integer value representing the combined flags.
        let rawValue: Int

        /// Supports 802.11b (old, slow, but compatible).
        static let mode11b = PHYFlags(rawValue: 1 << 0)

        /// Supports 802.11g (faster than b, common in 2.4GHz).
        static let mode11g = PHYFlags(rawValue: 1 << 1)

        /// Supports 802.11n (Wi-Fi 4, with MIMO for speed).
        static let mode11n = PHYFlags(rawValue: 1 << 2)

        /// Low-rate mode enabled (for power-saving or compatibility).
        static let lowRate = PHYFlags(rawValue: 1 << 3)

        /// Supports 802.11a (5GHz only, less interference).
        static let mode11a = PHYFlags(rawValue: 1 << 4)

        /// Supports 802.11ac (Wi-Fi 5, fast in 5GHz).
        static let mode11ac = PHYFlags(rawValue: 1 << 5)

        /// Supports 802.11ax (Wi-Fi 6, modern and efficient).
        static let mode11ax = PHYFlags(rawValue: 1 << 6)

        /// Wi-Fi Protected Setup (WPS) is supported for easy pairing.
        static let wps = PHYFlags(rawValue: 1 << 7)

        /// Fine Time Measurement (FTM) responder mode (for location services).
        static let ftmResponder = PHYFlags(rawValue: 1 << 8)

        /// Fine Time Measurement (FTM) initiator mode.
        static let ftmInitiator = PHYFlags(rawValue: 1 << 9)
    }
}

extension WIFIAccessPointRecord {
    /// Policies for how Wi-Fi country settings are applied.
    /// Mirrors ESP-IDF's `wifi_country_policy_t`.
    enum CountryPolicy: Int {
        /// Auto: Use the country's rules from the connected AP.
        /// Like asking the local expert instead of guessing.
        case auto = 0

        /// Manual: Always use the configured country settings.
        /// Stick to your own rules, no matter what.
        case manual
    }
}

extension WIFIAccessPointRecord {
    /// Country-specific Wi-Fi regulations and settings.
    struct WIFICountry {
        /// Country code as a string (e.g., "US", "JP").
        let countryCode: String

        /// Starting channel for allowed 2.4GHz Wi-Fi (usually 1).
        let startChannel: Int

        /// Total number of allowed 2.4GHz channels.
        let totalChannels: Int

        /// Maximum transmit power in dBm.
        let maxTxPower: Int

        /// Policy for applying these rules (auto or manual).
        let policy: CountryPolicy

        /// Bitmask for allowed 5GHz channels (if supported).
        let wifi5GChannelMask: Int?

        init(_ country: wifi_country_t) {
            let ccArray: [CChar] = withUnsafeBytes(of: country.cc) { buffer in
                Array(buffer.bindMemory(to: CChar.self))
            }
            self.countryCode = String(cString: ccArray)
            self.startChannel = Int(country.schan)
            self.totalChannels = Int(country.nchan)
            self.maxTxPower = Int(country.max_tx_power)
            self.policy = CountryPolicy(rawValue: Int(country.policy.rawValue)) ?? .auto
            self.wifi5GChannelMask = nil  // 5G channel mask not available for esp32c6
        }
    }
}

extension WIFIAccessPointRecord {
    /// High-Efficiency (Wi-Fi 6) AP information.
    struct HEAPInfo {
        /// BSS color value (0-63) for identifying the network.
        let bssColor: Int

        /// Whether AID assignment uses partial BSS color.
        let partialBssColor: Bool

        /// If BSS color usage is disabled.
        let bssColorDisabled: Bool

        /// Index for non-transmitted BSSID in M-BSSID sets.
        let bssidIndex: Int

        /// Initializes from ESP-IDF's C struct.
        init(_ he_ap: wifi_he_ap_info_t) {
            self.bssColor = Int(he_ap.bss_color)
            self.partialBssColor = he_ap.partial_bss_color != 0
            self.bssColorDisabled = he_ap.bss_color_disabled != 0
            self.bssidIndex = Int(he_ap.bssid_index)
        }
    }
}
