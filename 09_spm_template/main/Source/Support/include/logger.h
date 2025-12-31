
#include "esp_log.h"

static inline void shim_esp_log_level_local(const esp_log_config_t config,
                                            const char *tag,
                                            const char *message) {
    ESP_LOG_LEVEL_LOCAL(config.data, tag, "%s", message);
}
