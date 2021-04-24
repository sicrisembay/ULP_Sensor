/*
 * ULP assembly files are passed through C preprocessor first, so include directives
 * and C macros may be used in these files
 */
#include "soc/rtc_cntl_reg.h"
#include "soc/soc_ulp.h"
#include "sdkconfig.h"
#include "m_stack.S"
#include "m_routine.S"

#define CONFIGURATION_MODE_MASK     (0x0007)
#define CONFIGURATION_MODE_LSHIFT   (0)
#define CONFIGURATION_SADC_MASK     (0x0078)
#define CONFIGURATION_SADC_LSHIFT   (3)
#define CONFIGURATION_BADC_MASK     (0x0780)
#define CONFIGURATION_BADC_LSHIFT   (7)
#define CONFIGURATION_PGA_MASK      (0x1800)
#define CONFIGURATION_PGA_LSHIFT    (11)
#define CONFIGURATION_BRNG_MASK     (0x2000)
#define CONFIGURATION_BRNG_LSHIFT   (13)
#define CONFIGURATION_RST_MASK      (0x8000)
#define CONFIGURATION_RST_LSHIFT    (15)

#if (CONFIG_ULP_INA219_DEVICE_COUNT >= 1)
#define DEFAULT_CONFIGURATION_DEV1  (                                \
        (CONFIG_ULP_INA219_MODE_DEV1 << CONFIGURATION_MODE_LSHIFT) | \
        (CONFIG_ULP_INA219_SADC_DEV1 << CONFIGURATION_SADC_LSHIFT) | \
        (CONFIG_ULP_INA219_BADC_DEV1 << CONFIGURATION_BADC_LSHIFT) | \
        (CONFIG_ULP_INA219_PGA_DEV1 << CONFIGURATION_PGA_LSHIFT) |   \
        (CONFIG_ULP_INA219_BUS_DEV1 << CONFIGURATION_BRNG_LSHIFT)    \
    )
#endif /* #if (CONFIG_ULP_INA219_DEVICE_COUNT >= 1) */

#if (CONFIG_ULP_INA219_DEVICE_COUNT >= 2)
#define DEFAULT_CONFIGURATION_DEV2  (                                \
        (CONFIG_ULP_INA219_MODE_DEV2 << CONFIGURATION_MODE_LSHIFT) | \
        (CONFIG_ULP_INA219_SADC_DEV2 << CONFIGURATION_SADC_LSHIFT) | \
        (CONFIG_ULP_INA219_BADC_DEV2 << CONFIGURATION_BADC_LSHIFT) | \
        (CONFIG_ULP_INA219_PGA_DEV2 << CONFIGURATION_PGA_LSHIFT) |   \
        (CONFIG_ULP_INA219_BUS_DEV2 << CONFIGURATION_BRNG_LSHIFT)    \
    )
#endif /* #if (CONFIG_ULP_INA219_DEVICE_COUNT >= 2) */

#if (CONFIG_ULP_INA219_DEVICE_COUNT >= 3)
#define DEFAULT_CONFIGURATION_DEV3  (                                \
        (CONFIG_ULP_INA219_MODE_DEV3 << CONFIGURATION_MODE_LSHIFT) | \
        (CONFIG_ULP_INA219_SADC_DEV3 << CONFIGURATION_SADC_LSHIFT) | \
        (CONFIG_ULP_INA219_BADC_DEV3 << CONFIGURATION_BADC_LSHIFT) | \
        (CONFIG_ULP_INA219_PGA_DEV3 << CONFIGURATION_PGA_LSHIFT) |   \
        (CONFIG_ULP_INA219_BUS_DEV3 << CONFIGURATION_BRNG_LSHIFT)    \
    )
#endif /* #if (CONFIG_ULP_INA219_DEVICE_COUNT >= 3) */

/*
 * Constants
 */
    .set INA219_REG_ADDR_CONFIGURATION, 0x00
    .set INA219_REG_ADDR_SHUNT_VOLTAGE, 0x01
    .set INA219_REG_ADDR_BUS_VOLTAGE, 0x02
    .set INA219_REG_ADDR_POWER, 0x03
    .set INA219_REG_ADDR_CURRENT, 0x04
    .set INA219_REG_ADDR_CALIBRATION, 0x05

/*
 * Variable: ina219_init_done
 * Description: initialization done flag
 */
    .bss
    .global ina219_init_done
ina219_init_done:
    .long 0

/*
 * Variable: ina219_dev_id
 * Description: Device ID
 */
    .bss
    .global ina219_dev_id
ina219_dev_id:
#if (CONFIG_ULP_INA219_DEVICE_COUNT >= 1)
    .long 0
#endif /* (CONFIG_ULP_INA219_DEVICE_COUNT >= 1) */
#if (CONFIG_ULP_INA219_DEVICE_COUNT >= 2)
    .long 0
#endif /* (CONFIG_ULP_INA219_DEVICE_COUNT >= 2) */
#if (CONFIG_ULP_INA219_DEVICE_COUNT >= 3)
    .long 0
#endif /* (CONFIG_ULP_INA219_DEVICE_COUNT >= 3) */

    .global ina219_reg_configuration_dev1
ina219_reg_configuration_dev1:
    .long 0
#if (CONFIG_ULP_INA219_DEVICE_COUNT >= 2)
    .global ina219_reg_configuration_dev2
ina219_reg_configuration_dev2:
    .long 0
#endif

#if (CONFIG_ULP_INA219_DEVICE_COUNT >= 3)
    .global ina219_reg_configuration_dev3
ina219_reg_configuration_dev3:
    .long 0
#endif


/*
 * Routine: ina219_init
 * Description: Initialize INA219 Device
 * Affects: R0, R1, R2 (LR), R3(STACK)
 *
 * STACK (R3)
 * ------------------------------------
 * SP(4)  --> Caller return address
 * SP(0)  --> NULL
 */
    .text
    .global ina219_init
ina219_init:
    /* Check initialization flag */
    move r1, ina219_init_done
    ld r0, r1, 0
    jumpr init_done, 1, ge
    /*
     * Not yet initialized
     */
    /* Set initialization flag */
    move r0, 0x01
    st r0, r1, 0

#if (CONFIG_ULP_INA219_DEVICE_COUNT >= 1)
    /* Initialize Device ID  variable */
    move r1, ina219_dev_id
    move r0, CONFIG_ULP_INA219_ADDR_DEV1
    st r0, r1, 0    // ina219_dev_id[0] = CONFIG_ULP_INA219_ADDR_DEV1
    /* Configuration Register */
    move r1, ina219_reg_configuration_dev1
    move r0, DEFAULT_CONFIGURATION_DEV1
    st r0, r1, 0
    /* Device Addres --> push to stack */
    move r1, ina219_dev_id
    ld r0, r1, 0
    push r0
    /* INA219 Register --> push to stack */
    move r0, INA219_REG_ADDR_CONFIGURATION
    push r0
    /* Value */
    move r1, ina219_reg_configuration_dev1
    ld r0, r1, 0
    push r0
    rcall ina219_write_reg
#endif /* (CONFIG_ULP_INA219_DEVICE_COUNT >= 1) */

#if (CONFIG_ULP_INA219_DEVICE_COUNT >= 2)
    /* Initialize Device ID  variable */
    move r1, ina219_dev_id
    move r0, CONFIG_ULP_INA219_ADDR_DEV2
    st r0, r1, 4    // ina219_dev_id[1] = CONFIG_ULP_INA219_ADDR_DEV2
    /* Configuration Register */
    move r1, ina219_reg_configuration_dev2
    move r0, DEFAULT_CONFIGURATION_DEV2
    st r0, r1, 0
    /* Device Addres --> push to stack */
    move r1, ina219_dev_id
    ld r0, r1, 4
    push r0
    /* INA219 Register --> push to stack */
    move r0, INA219_REG_ADDR_CONFIGURATION
    push r0
    /* Value */
    move r1, ina219_reg_configuration_dev2
    ld r0, r1, 0
    push r0
    rcall ina219_write_reg
#endif /* (CONFIG_ULP_INA219_DEVICE_COUNT >= 2) */

#if (CONFIG_ULP_INA219_DEVICE_COUNT >= 3)
    /* Initialize Device ID  variable */
    move r1, ina219_dev_id
    move r0, CONFIG_ULP_INA219_ADDR_DEV3
    st r0, r1, 8    // ina219_dev_id[3] = CONFIG_ULP_INA219_ADDR_DEV3
    /* Configuration Register */
    move r1, ina219_reg_configuration_dev3
    move r0, DEFAULT_CONFIGURATION_DEV3
    st r0, r1, 0
    /* Device Addres --> push to stack */
    move r1, ina219_dev_id
    ld r0, r1, 8
    push r0
    /* INA219 Register --> push to stack */
    move r0, INA219_REG_ADDR_CONFIGURATION
    push r0
    /* Value */
    move r1, ina219_reg_configuration_dev3
    ld r0, r1, 0
    push r0
    rcall ina219_write_reg
#endif /* (CONFIG_ULP_INA219_DEVICE_COUNT >= 3) */
init_done:
    ret


/*
 * Routine: ina219_set_mode
 * Description: Set INA219 Mode
 *
 * Input:
 *    R0 : Device ID
 *    R1 : Mode (see datasheet)
 * Return
 *    None
 *
 * STACK (R3)
 * ------------------------------------
 * SP(4)  --> Caller return address
 * SP(0)  --> NULL
 */
    .text
    .global ina219_set_mode
ina219_set_mode:
    ret

/*
 * Routine: ina219_write_reg
 * Description: Initialize INA219 Device
 * Affects: R0, R1, R2 (LR), R3(STACK)
 * 
 * STACK (R3)
 * ------------------------------------
 * SP(16) --> Device Address
 * SP(12) --> Register
 * SP(8)  --> Value
 * SP(4)  --> Caller return address
 * SP(0)  --> NULL
 */
    .text
    .global ina219_write_reg
ina219_write_reg:
    /* I2C start */
    rcall i2c_start_cond
    /* Device Address */
    ld r1, r3, 16
    lsh r1, r1, 1
    rcall i2c_write_byte
    /* Register */
    ld r1, r3, 12
    rcall i2c_write_byte
    /* Data (swapped) */
    ld r1, r3, 8
    rsh r1, r1, 8
    rcall i2c_write_byte
    ld r1, r3, 8
    rcall i2c_write_byte
    /* I2C stop */
    rcall i2c_stop_cond

    /* Pop Stack */
    pop r2 // <-- caller return address
    pop r1 // value
    pop r1 // register
    pop r1 // Device Address
    jump r2