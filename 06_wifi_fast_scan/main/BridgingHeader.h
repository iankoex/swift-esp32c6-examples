
#include <stdio.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include "esp_chip_info.h"
#include "sdkconfig.h"

// for wifi related functions
#include "esp_event.h" // IP
#include "esp_log.h"
#include "esp_wifi.h"
#include "nvs_flash.h"

// #pragma once to prevent error: redefinition of 'shim_wifi_init_config
#pragma once

// work around for embedded swift not supporting complex macros
// see
// https://developer.apple.com/documentation/swift/using-imported-c-macros-in-swift
static inline wifi_init_config_t shim_wifi_init_config(void) {
  wifi_init_config_t config = WIFI_INIT_CONFIG_DEFAULT();
  return config;
}
