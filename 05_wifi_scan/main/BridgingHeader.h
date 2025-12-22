
#include <stdio.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "sdkconfig.h"
#include "esp_chip_info.h"

// for reading the temperature
#include "nvs_flash.h"
#include "esp_wifi.h"
#include <string.h>

// #pragma once to prevent error: redefinition of 'shim_wifi_init_config
#pragma once

// work around for embedded swift not supporting complex macros
// see https://developer.apple.com/documentation/swift/using-imported-c-macros-in-swift
static inline wifi_init_config_t shim_wifi_init_config(void) {
    wifi_init_config_t config = WIFI_INIT_CONFIG_DEFAULT();
    return config;
}
