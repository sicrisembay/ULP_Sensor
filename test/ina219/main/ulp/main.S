#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"
#include "m_stack.S"
#include "m_routine.S"

    .bss
    .global stackStart
stackStart:
    .skip 100
    .global stackEnd
stackEnd:
    .long 0

    .global ina219_shunt_voltage
ina219_shunt_voltage:
    .long 0

    .global ina219_bus_voltage
ina219_bus_voltage:
    .long 0

    .global ina219_power
ina219_power:
    .long 0

    .global ina219_current
ina219_current:
    .long 0

    /* Code goes into .text section */
    .text
    .global entry
entry:
    /* Initialize Stack */
    stack_init
    /* Simple Test Routine */
    rcall test_ina219
    jump wake_up

test_ina219:
    rcall ina219_init
    /*
     * Dev1 MODE Power Up
     *    R0 : Device ID
     *    R1 : Mode (see datasheet) is 0x3
     */
    move r0, 0
    move r1, 3  // Shunt and bus, trigger
    rcall ina219_set_mode
    /* Delay for minimum of 68.14ms */
    //  68.14ms = (2 + cycles + 4)(8MHz)
    //  cycle = 272,554
    wait 0xFFFF
    wait 0xFFFF
    wait 0xFFFF
    wait 0xFFFF
    wait 0xFFFF
    wait 0xFFFF
    wait 0xFFFF
    wait 0xFFFF
    wait 20826

    /* Read Shunt Voltage */
    move r0, 0x00
    rcall ina219_read_shunt_voltage
    move r1, ina219_shunt_voltage
    st r0, r1, 0
    /* Read Bus Voltage Register */
    move r0, 0x00
    rcall ina219_read_bus_voltage
    move r1, ina219_bus_voltage
    st r0, r1, 0
    /* Read Power */
    move r0, 0x00
    rcall ina219_read_power
    move r1, ina219_power
    st r0, r1, 0
    /* Read Current */
    move r0, 0x00
    rcall ina219_read_current
    move r1, ina219_current
    st r0, r1, 0
    /*
     * Dev1 MODE Power Down
     *    R0 : Device ID
     *    R1 : Mode (see datasheet) is 0x0
     */
    move r0, 0
    move r1, 0  // Power down
    rcall ina219_set_mode
    ret
