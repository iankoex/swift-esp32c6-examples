
#include <stdio.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "sdkconfig.h"
#include "esp_chip_info.h"

// for controlling led
#include "driver/gpio.h"
#include "led_strip.h"
