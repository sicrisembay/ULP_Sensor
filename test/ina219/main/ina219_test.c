#include <stdio.h>
#include "esp_sleep.h"
#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/sens_reg.h"
#include "soc/soc.h"
#include "driver/gpio.h"
#include "driver/rtc_io.h"
#include "esp32/ulp.h"
#include "sdkconfig.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "ulp_main.h"

#define CONCAT(x,y)         x##y
#define CONCAT_L1(x,y)      CONCAT(x,y)

#define ESP32_SDA_GPIO_NUM  CONCAT_L1(GPIO_NUM_, CONFIG_ESP32_I2C_SDA_IO)
#define ESP32_SCL_GPIO_NUM  CONCAT_L1(GPIO_NUM_, CONFIG_ESP32_I2C_SCL_IO)

extern const uint8_t ulp_main_bin_start[] asm("_binary_ulp_main_bin_start");
extern const uint8_t ulp_main_bin_end[]   asm("_binary_ulp_main_bin_end");

static void init_ulp_program()
{
    rtc_gpio_init(ESP32_SDA_GPIO_NUM);
    rtc_gpio_set_direction(ESP32_SDA_GPIO_NUM, RTC_GPIO_MODE_INPUT_ONLY);
    rtc_gpio_init(ESP32_SCL_GPIO_NUM);
    rtc_gpio_set_direction(ESP32_SCL_GPIO_NUM, RTC_GPIO_MODE_INPUT_ONLY);

    esp_err_t err = ulp_load_binary(0, ulp_main_bin_start,
            (ulp_main_bin_end - ulp_main_bin_start) / sizeof(uint32_t));
    ESP_ERROR_CHECK(err);

    ulp_ina219_init_done = 0;

    /* Set ULP wake up period to T = 10s.
     * Minimum pulse width has to be T * (ulp_debounce_counter + 1) = 80ms.
     */
    ulp_set_wakeup_period(0, 10000000);

    /* Start the program */
    err = ulp_run(&ulp_entry - RTC_SLOW_MEM);
    ESP_ERROR_CHECK(err);

}

void app_main()
{
    esp_sleep_wakeup_cause_t cause = esp_sleep_get_wakeup_cause();
    if (cause != ESP_SLEEP_WAKEUP_ULP) {
        printf("Not ULP wakeup, initializing ULP\n");
        init_ulp_program();
    } else {

        printf("ULP wakeup\n");
    }
    printf("ina219 init flag: %04X\n", (short)ulp_ina219_init_done);
    printf("ina219 bus voltage reg: %0.1fV\n", 0.004f * ((short)ulp_ina219_bus_regVal >> 3));
    printf("Entering deep sleep\n\n");
    ESP_ERROR_CHECK( esp_sleep_enable_ulp_wakeup() );
    esp_deep_sleep_start();
}