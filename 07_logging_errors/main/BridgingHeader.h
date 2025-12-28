
/**
 * @file BridgingHeader.h
 * @brief Header file for bridging C functions to Swift in a ESP32-C6 project.
 *
 * This header provides necessary includes and shim functions to interface
 * ESP-IDF C APIs with Swift code. It works around limitations of Embedded Swift
 * with complex C macros.
 *
 * @note IWYU pragmas are used to suppress unused-include warnings.
 * Although language servers like clangd may mark these includes as unused,
 * they are actually required by Swift code that imports this bridging header.
 * The includes provide type definitions, macros, and declarations that are not
 * directly referenced in this C header but are essential for Swift bridging.
 */

#include <stdio.h> // IWYU pragma: keep - Required for ESP-IDF logging types and functions used in Swift bridging

#include "freertos/FreeRTOS.h" // IWYU pragma: keep - Provides FreeRTOS types that may be indirectly referenced in ESP-IDF APIs

#include "esp_chip_info.h" // IWYU pragma: keep - Needed for esp_chip_info_t and related functions used in ChipInformation.swift

#include "sdkconfig.h" // IWYU pragma: keep - Contains SDK configuration definitions used in ChipInformation.swift

#include "esp_log.h" // IWYU pragma: keep - Essential for esp_log_config_t and ESP_LOG_LEVEL_LOCAL macro used in Logger.swift

// Prevent multiple inclusions of this header
#pragma once

/**
 * @brief Workaround for Embedded Swift not supporting complex C macros.
 *
 * Embedded Swift has limitations with importing complex C preprocessor macros.
 * This shim provides a C function interface to ESP-IDF's logging system.
 *
 * @see
 * https://developer.apple.com/documentation/swift/using-imported-c-macros-in-swift
 */
static inline void shim_esp_log_level_local(const esp_log_config_t config,
                                            const char *tag,
                                            const char *message) {
  ESP_LOG_LEVEL_LOCAL(config.data, tag, "%s", message);
}
