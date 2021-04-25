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
#define CONFIGURATION_MODE_CLR_MASK (0xFFF8)
#define CONFIGURATION_MODE_LSHIFT   (0)
#define CONFIGURATION_SADC_MASK     (0x0078)
#define CONFIGURATION_SADC_CLR_MASK (0xFF87)
#define CONFIGURATION_SADC_LSHIFT   (3)
#define CONFIGURATION_BADC_MASK     (0x0780)
#define CONFIGURATION_BADC_CLR_MASK (0xF87F)
#define CONFIGURATION_BADC_LSHIFT   (7)
#define CONFIGURATION_PGA_MASK      (0x1800)
#define CONFIGURATION_PGA_CLR_MASK  (0xE7FF)
#define CONFIGURATION_PGA_LSHIFT    (11)
#define CONFIGURATION_BRNG_MASK     (0x2000)
#define CONFIGURATION_BRNG_CLR_MASK (0xDFFF)
#define CONFIGURATION_BRNG_LSHIFT   (13)
#define CONFIGURATION_RST_MASK      (0x8000)
#define CONFIGURATION_RST_CLR_MASK  (0x7FFF)
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
 * Variable: ina219_dev_addr[3]
 * Description: I2C Device Address
 */
    .bss
ina219_dev_addr:
    .long 0
    .long 0
    .long 0


/*
 * Variable: ina219_reg_configuration[3]
 * Description: INA219 configuration register value
 */
    .bss
ina219_reg_configuration:
    .long 0
    .long 0
    .long 0


/*
 * Variable: ina219_reg_calibration[3]
 * Description: INA219 calibration register value
 */
    .bss
ina219_reg_calibration:
    .long 0
    .long 0
    .long 0

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

    /* Clear Variable */
    move r0, 0
    move r1, ina219_dev_addr
    st r0, r1, 0
    st r0, r1, 4
    st r0, r1, 8
    move r1, ina219_reg_configuration
    st r0, r1, 0
    st r0, r1, 4
    st r0, r1, 8
    move r1, ina219_reg_calibration
    st r0, r1, 0
    st r0, r1, 4
    st r0, r1, 8

#if (CONFIG_ULP_INA219_DEVICE_COUNT >= 1)
    /* Initialize Device ID  variable */
    move r1, ina219_dev_addr
    move r0, CONFIG_ULP_INA219_ADDR_DEV1
    st r0, r1, 0    // ina219_dev_addr[0] = CONFIG_ULP_INA219_ADDR_DEV1
    /* Configuration Register */
    move r1, ina219_reg_configuration
    move r0, DEFAULT_CONFIGURATION_DEV1
    st r0, r1, 0
    /*
     * Initialize INA219 Dev1 Configurtion
     *   Prepare Stack Frame for ina219_write_reg
     *     SP --> Device Address
     *     SP --> Register
     *     SP --> 16-bit value
     */
    move r1, ina219_dev_addr
    ld r0, r1, 0
    push r0 // Device Address
    move r0, INA219_REG_ADDR_CONFIGURATION
    push r0 // Register
    move r1, ina219_reg_configuration
    ld r0, r1, 0
    push r0 // 16-bit value
    rcall ina219_write_reg
    /*
     * Initialize INA219 Dev1 Calibration
     *   Prepare Stack Frame for ina219_write_reg
     *     SP --> Device Address
     *     SP --> Register
     *     SP --> 16-bit value
     */
    move r1, ina219_dev_addr
    ld r0, r1, 0
    push r0 // Device Address
    move r0, INA219_REG_ADDR_CALIBRATION
    push r0 // Register
    move r1, ina219_reg_calibration
    move r0, CONFIG_ULP_INA219_CAL_FS_DEV1
    st r0, r1, 0
    push r0 // 16-bit value
    rcall ina219_write_reg
#endif /* (CONFIG_ULP_INA219_DEVICE_COUNT >= 1) */

#if (CONFIG_ULP_INA219_DEVICE_COUNT >= 2)
    /* Initialize Device ID  variable */
    move r1, ina219_dev_addr
    move r0, CONFIG_ULP_INA219_ADDR_DEV2
    st r0, r1, 4    // ina219_dev_addr[1] = CONFIG_ULP_INA219_ADDR_DEV2
    /* Configuration Register */
    move r1, ina219_reg_configuration
    move r0, DEFAULT_CONFIGURATION_DEV2
    st r0, r1, 4
    /*
     * Initialize INA219 Dev2 Configuration
     *   Prepare Stack Frame for ina219_write_reg
     *     SP --> Device Address
     *     SP --> Register
     *     SP --> 16-bit value
     */
    move r1, ina219_dev_addr
    ld r0, r1, 4
    push r0 // Device Address
    move r0, INA219_REG_ADDR_CONFIGURATION
    push r0 // Register
    move r1, ina219_reg_configuration
    ld r0, r1, 4
    push r0 // 16-bit value
    rcall ina219_write_reg
    /*
     * Initialize INA219 Dev2 Calibration
     *   Prepare Stack Frame for ina219_write_reg
     *     SP --> Device Address
     *     SP --> Register
     *     SP --> 16-bit value
     */
    move r1, ina219_dev_addr
    ld r0, r1, 4
    push r0 // Device Address
    move r0, INA219_REG_ADDR_CALIBRATION
    push r0 // Register
    move r1, ina219_reg_calibration
    move r0, CONFIG_ULP_INA219_CAL_FS_DEV2
    st r0, r1, 4
    push r0 // 16-bit value
    rcall ina219_write_reg
#endif /* (CONFIG_ULP_INA219_DEVICE_COUNT >= 2) */

#if (CONFIG_ULP_INA219_DEVICE_COUNT >= 3)
    /* Initialize Device ID  variable */
    move r1, ina219_dev_addr
    move r0, CONFIG_ULP_INA219_ADDR_DEV3
    st r0, r1, 8    // ina219_dev_addr[3] = CONFIG_ULP_INA219_ADDR_DEV3
    /* Configuration Register */
    move r1, ina219_reg_configuration
    move r0, DEFAULT_CONFIGURATION_DEV3
    st r0, r1, 8
    /*
     * Initialize INA219 Dev3 Configuration
     *   Prepare Stack Frame for ina219_write_reg
     *     SP --> Device Address
     *     SP --> Register
     *     SP --> 16-bit value
     */
    move r1, ina219_dev_addr
    ld r0, r1, 8
    push r0 // Device Address
    move r0, INA219_REG_ADDR_CONFIGURATION
    push r0 // Register
    move r1, ina219_reg_configuration
    ld r0, r1, 8
    push r0 // 16-bit value
    rcall ina219_write_reg
    /*
     * Initialize INA219 Dev3 Calibration
     *   Prepare Stack Frame for ina219_write_reg
     *     SP --> Device Address
     *     SP --> Register
     *     SP --> 16-bit value
     */
    move r1, ina219_dev_addr
    ld r0, r1, 8
    push r0 // Device Address
    move r0, INA219_REG_ADDR_CALIBRATION
    push r0 // Register
    move r1, ina219_reg_calibration
    move r0, CONFIG_ULP_INA219_CAL_FS_DEV3
    st r0, r1, 8
    push r0 // 16-bit value
    rcall ina219_write_reg
#endif /* (CONFIG_ULP_INA219_DEVICE_COUNT >= 3) */
init_done:
    ret


/*
 * Routine: ina219_write_reg
 * Description: Write 16-bit value to a register
 * Affects: R0, R1, R2 (LR), R3(STACK)
 * 
 * STACK (R3)
 * ------------------------------------
 * SP(16) --> Device Address
 * SP(12) --> Register
 * SP(8)  --> 16-bit value
 * SP(4)  --> Caller return address
 * SP(0)  --> NULL
 */
    .text
ina219_write_reg:
    /* I2C start */
    rcall i2c_start_cond
    /* Device Address (write) */
    ld r1, r3, 16
    lsh r1, r1, 1
    rcall i2c_write_byte
    /* Register */
    ld r1, r3, 12
    rcall i2c_write_byte
    /* Data[b15:b8] */
    ld r1, r3, 8
    rsh r1, r1, 8
    rcall i2c_write_byte
    /* Data[b7:b0] */
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

/*
 * Routine: ina219_read_reg
 * Description: Read 16-bit value from a register
 * Affects: R0, R1, R2 (LR), R3(STACK)
 *
 * Input:
 *    None
 *
 * Return:
 *    R0 : Value (16-bit)
 *
 * STACK (R3)
 * ------------------------------------
 * SP(12) --> Device Address
 * SP(8)  --> Register
 * SP(4)  --> Caller return address
 * SP(0)  --> NULL
 */
    .text
ina219_read_reg:
    /* I2C start */
    rcall i2c_start_cond
    /* Device Address (write) */
    ld r1, r3, 12
    lsh r1, r1, 1
    rcall i2c_write_byte
    /* Register */
    ld r1, r3, 8
    rcall i2c_write_byte
    /* Restart + Device Address + Read */
    rcall i2c_start_cond
    ld r1, r3, 12
    lsh r1, r1, 1
    or r1, r1, 0x01
    rcall i2c_write_byte
    /* Read MSB (ACK) */
    move r1, 0
    rcall i2c_read_byte
    push r0
    /* Read LSB (NACK) */
    move r1, 1
    rcall i2c_read_byte
    push r0
    /* I2C stop */
    rcall i2c_stop_cond
    /* MSB:LSB */
    pop r0 // LSB
    pop r1 // MSB
    lsh r1, r1, 8
    or r0, r0, r1 // R0 <-- MSB:LSB
    /* Pop Stack */
    pop r2 // <-- caller return address
    pop r1 // register
    pop r1 // Device Address
    jump r2


/*
 * Routine: ina219_devId_to_devAddr
 * Description: Convert from Device ID to I2C address
 * Affects: R0, R1, R2 (LR), R3(STACK)
 *
 * Input:
 *    R0 : Device ID
 *
 * Return:
 *    R0 : I2C 7-bit Address
 *
 * STACK (R3)
 * ------------------------------------
 * SP(4)  --> Caller return address
 * SP(0)  --> NULL
 */
    .text
ina219_devId_to_devAddr:
    // calculate array offset
    lsh r0, r0, 2 // DeviceID * 4
    // Get address
    move r1, ina219_dev_addr
    add r1, r0, r1
    ld r0, r1, 0
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
    push r0
    push r1
    /*
     * Stack after push
     *   SP(12) --> Caller return address
     *   SP(8)  --> Dev ID
     *   SP(4)  --> Mode Value
     *   SP(0)  -->
     */
    /* Array offset */
    lsh r0, r0, 2
    /* Mode */
    move r1, ina219_reg_configuration
    add r1, r0, r1
    push r1
    /*
     * Stack after push
     *   SP(16) --> Caller return address
     *   SP(12) --> Dev ID
     *   SP(8)  --> Mode Value
     *   SP(4)  --> Address of ina219_reg_configuration[offset]
     *   SP(0)  -->
     */
    ld r0, r1, 0
    and r0, r0, CONFIGURATION_MODE_CLR_MASK
    ld r1, r3, 8 // r1 = mode Value
    lsh r1, r1, CONFIGURATION_MODE_LSHIFT
    or r0, r0, r1
    st r0, r3, 4 // ina219_reg_configuration[offset] = r0

    /*
     * Prepare Stack Frame for ina219_write_reg
     *   SP --> Device Address
     *   SP --> Register
     *   SP --> 16-bit value
     */
    ld r0, r3, 12
    rcall ina219_devId_to_devAddr
    push r0  // Device Address
    move r0, INA219_REG_ADDR_CONFIGURATION
    push r0 // Register
    /*
     * Stack after push
     *   SP(24) --> Caller return address
     *   SP(20) --> Dev ID
     *   SP(16) --> Mode Value
     *   SP(12) --> Address of ina219_reg_configuration[offset]
     *   SP(8)  --> Device Address
     *   SP(4)  --> Register
     *   SP(0)  -->
     */
    ld r0, r3, 12
    push r0
    /*
     * Stack after push
     *   SP(28) --> Caller return address
     *   SP(24) --> Dev ID
     *   SP(20) --> Mode Value
     *   SP(16) --> Address of ina219_reg_configuration[offset]
     *   SP(12) --> Device Address
     *   SP(8)  --> Register
     *   SP(4)  --> 16-bit value of ina219_reg_configuration[offset]
     *   SP(0)  -->
     */
    rcall ina219_write_reg
    /*
     * Stack after rcall
     *   SP(16) --> Caller return address
     *   SP(12) --> Dev ID
     *   SP(8)  --> Mode Value
     *   SP(4)  --> Address of ina219_reg_configuration[offset]
     *   SP(0)  -->
     */
    pop r0
    pop r0
    pop r0
    /*
     * Stack after pop
     *   SP(4)  --> Caller return address
     *   SP(0)  -->
     */
    ret


/*
 * Routine: ina219_read_shunt_voltage
 * Description: Read shunt voltage measurement
 * Affects: R0, R1, R2 (LR), R3(STACK)
 *
 * Input:
 *    R0 : Device ID
 *
 * Return:
 *    R0 : Value (16-bit)
 *
 * STACK (R3)
 * ------------------------------------
 * SP(4)  --> Caller return address
 * SP(0)  --> NULL
 */
    .text
    .global ina219_read_shunt_voltage
ina219_read_shunt_voltage:
    /* Get Device Address from Device ID */
    rcall ina219_devId_to_devAddr
    /*
     * Prepare Stack Frame
     * SP --> Device Address
     * SP --> Register
     */
    push r0 // device address
    move r0, INA219_REG_ADDR_SHUNT_VOLTAGE
    push r0 // register
    rcall ina219_read_reg
    ret


/*
 * Routine: ina219_read_bus_voltage
 * Description: Read bus voltage measurement
 * Affects: R0, R1, R2 (LR), R3(STACK)
 *
 * Input:
 *    R0 : Device ID
 *
 * Return:
 *    R0 : Value (16-bit)
 *
 * STACK (R3)
 * ------------------------------------
 * SP(4)  --> Caller return address
 * SP(0)  --> NULL
 */
    .text
    .global ina219_read_bus_voltage
ina219_read_bus_voltage:
    /* Get Device Address from Device ID */
    rcall ina219_devId_to_devAddr
    /*
     * Prepare Stack Frame
     * SP --> Device Address
     * SP --> Register
     */
    push r0 // device address
    move r0, INA219_REG_ADDR_BUS_VOLTAGE
    push r0 // register
    rcall ina219_read_reg
    ret


/*
 * Routine: ina219_read_power
 * Description: Read power measurement
 * Affects: R0, R1, R2 (LR), R3(STACK)
 *
 * Input:
 *    R0 : Device ID
 *
 * Return:
 *    R0 : Value (16-bit)
 *
 * STACK (R3)
 * ------------------------------------
 * SP(4)  --> Caller return address
 * SP(0)  --> NULL
 */
    .text
    .global ina219_read_power
ina219_read_power:
    /* Get Device Address from Device ID */
    rcall ina219_devId_to_devAddr
    /*
     * Prepare Stack Frame
     * SP --> Device Address
     * SP --> Register
     */
    push r0 // device address
    move r0, INA219_REG_ADDR_POWER
    push r0 // register
    rcall ina219_read_reg
    ret


/*
 * Routine: ina219_read_current
 * Description: Read current measurement
 * Affects: R0, R1, R2 (LR), R3(STACK)
 *
 * Input:
 *    R0 : Device ID
 *
 * Return:
 *    R0 : Value (16-bit)
 *
 * STACK (R3)
 * ------------------------------------
 * SP(4)  --> Caller return address
 * SP(0)  --> NULL
 */
    .text
    .global ina219_read_current
ina219_read_current:
    /* Get Device Address from Device ID */
    rcall ina219_devId_to_devAddr
    /*
     * Prepare Stack Frame
     * SP --> Device Address
     * SP --> Register
     */
    push r0 // device address
    move r0, INA219_REG_ADDR_CURRENT
    push r0 // register
    rcall ina219_read_reg
    ret
