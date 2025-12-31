import Logging
import Support

@_cdecl("app_main")
func main() {
    print("Hello from Swift on ESP32C6!")
    let logger = Logger(label: "app")
    logger.info("some info")
}
