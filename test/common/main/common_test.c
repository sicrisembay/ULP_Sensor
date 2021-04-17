#include <stdio.h>
#include "esp_sleep.h"
#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/sens_reg.h"
#include "soc/soc.h"
#include "driver/gpio.h"
#include "driver/rtc_io.h"
#include "esp32/ulp.h"

#include "ulp_main.h"
extern const uint8_t ulp_main_bin_start[] asm("_binary_ulp_main_bin_start");
extern const uint8_t ulp_main_bin_end[]   asm("_binary_ulp_main_bin_end");

static void init_ulp_program()
{
//    rtc_gpio_init(gpio_scl);
//    rtc_gpio_set_direction(gpio_scl, RTC_GPIO_MODE_INPUT_ONLY);
//    rtc_gpio_init(gpio_sda);
//    rtc_gpio_set_direction(gpio_sda, RTC_GPIO_MODE_INPUT_ONLY);

    esp_err_t err = ulp_load_binary(0, ulp_main_bin_start,
            (ulp_main_bin_end - ulp_main_bin_start) / sizeof(uint32_t));
    ESP_ERROR_CHECK(err);

    /* Set ULP wake up period to T = 1000ms
     * Minimum pulse width has to be T * (ulp_debounce_counter + 1) = 80ms.
     */
    REG_SET_FIELD(SENS_ULP_CP_SLEEP_CYC0_REG, SENS_SLEEP_CYCLES_S0, 1500000);

}

void app_main()
{
    esp_sleep_wakeup_cause_t cause = esp_sleep_get_wakeup_cause();
    if (cause != ESP_SLEEP_WAKEUP_ULP) {
        printf("Not ULP wakeup, initializing ULP\n");
        init_ulp_program();
    } else {

        printf("ULP wakeup, printing status\n");
//        print_status();
    }

    printf("Entering deep sleep\n\n");

    ESP_ERROR_CHECK( esp_sleep_enable_ulp_wakeup() );

    /* Start the program */
    esp_err_t err = ulp_run(&ulp_entry - RTC_SLOW_MEM);
    ESP_ERROR_CHECK(err);

    esp_deep_sleep_start();
}